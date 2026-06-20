import AVFoundation
import Foundation

struct VideoOptimizer: Sendable {
    func optimize(
        job: MediaJob,
        to destination: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let asset = AVURLAsset(url: job.fileURL)

        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw ProcessingError.exportFailed
        }

        let duration = try await asset.load(.duration)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        let frameRate = Double(nominalFrameRate > 0 ? nominalFrameRate : 30)

        // Size after the track's rotation is applied (so portrait video stays portrait).
        let oriented = naturalSize.applying(transform)
        let sourceWidth = abs(oriented.width)
        let sourceHeight = abs(oriented.height)
        let (outWidth, outHeight) = Self.outputSize(width: sourceWidth, height: sourceHeight, resolution: job.resolution)

        let totalSeconds = max(0.1, duration.seconds)
        // Guard against unreadable fileSize — if 0, skip the source-bitrate cap entirely.
        let sourceBitrate = job.fileSize > 0 ? Double(job.fileSize) * 8 / totalSeconds : Double.infinity
        let desired = Double(outWidth * outHeight) * frameRate * job.quality.bitsPerPixel
        let videoBitrate = max(500_000, Int(min(desired, sourceBitrate * 0.95)))

        let reader = try AVAssetReader(asset: asset)

        // Build a composition with explicit scale+orientation instructions so we
        // get a proper scaled-down output, not just a top-left crop of the source.
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: outWidth, height: outHeight)
        let fps = CMTimeScale(max(1, Int(frameRate.rounded())))
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: fps)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        // Step 1: apply preferredTransform (handles rotation/mirroring from device orientation).
        // Step 2: scale from oriented source dimensions down to the output dimensions.
        let scaleX = CGFloat(outWidth) / sourceWidth
        let scaleY = CGFloat(outHeight) / sourceHeight
        layerInstruction.setTransform(
            transform.concatenating(CGAffineTransform(scaleX: scaleX, y: scaleY)),
            at: .zero
        )
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let videoOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: videoTracks,
            videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        )
        videoOutput.videoComposition = videoComposition
        videoOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(videoOutput) else { throw ProcessingError.exportFailed }
        reader.add(videoOutput)

        var audioOutput: AVAssetReaderTrackOutput?
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let output = AVAssetReaderTrackOutput(
                track: audioTrack,
                outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM]
            )
            output.alwaysCopiesSampleData = false
            if reader.canAdd(output) {
                reader.add(output)
                audioOutput = output
            }
        }

        try? FileManager.default.removeItem(at: destination)
        let writer = try AVAssetWriter(
            outputURL: destination,
            fileType: job.outputFormat.resolvedFileType(sourceExtension: job.fileURL.pathExtension)
        )

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: outWidth,
            AVVideoHeightKey: outHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: videoBitrate,
                AVVideoMaxKeyFrameIntervalKey: Int(frameRate * 2),
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoAllowFrameReorderingKey: true
            ]
        ])
        videoInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(videoInput) else { throw ProcessingError.exportFailed }
        writer.add(videoInput)

        var audioInput: AVAssetWriterInput?
        if audioOutput != nil {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44_100,
                AVEncoderBitRateKey: 192_000
            ])
            input.expectsMediaDataInRealTime = false
            if writer.canAdd(input) {
                writer.add(input)
                audioInput = input
            }
        }

        guard reader.startReading() else { throw reader.error ?? ProcessingError.exportFailed }
        guard writer.startWriting() else { throw writer.error ?? ProcessingError.exportFailed }
        writer.startSession(atSourceTime: .zero)

        let box = PumpBox(
            reader: reader,
            writer: writer,
            videoInput: videoInput,
            videoOutput: videoOutput,
            audioInput: audioInput,
            audioOutput: audioOutput,
            totalSeconds: totalSeconds,
            progress: progress
        )

        try await withTaskCancellationHandler {
            try await box.run()
        } onCancel: {
            box.cancel()
        }

        progress(1)
    }

    /// Scales by the smaller edge so both orientations work; rounds to even
    /// dimensions (required by H.264) and never upscales.
    private static func outputSize(width: CGFloat, height: CGFloat, resolution: ResolutionOption) -> (Int, Int) {
        func even(_ value: CGFloat) -> Int {
            let rounded = max(2, Int(value.rounded()))
            return rounded - (rounded % 2)
        }

        guard let target = resolution.pixels else {
            return (even(width), even(height))
        }
        let minEdge = min(width, height)
        guard minEdge > CGFloat(target) else {
            return (even(width), even(height))
        }
        let scale = CGFloat(target) / minEdge
        return (even(width * scale), even(height * scale))
    }
}

/// Drives the reader/writer pump. AVFoundation's reader/writer objects aren't
/// Sendable but are confined to this box and its serial callbacks, so the box is
/// `@unchecked Sendable`.
private final class PumpBox: @unchecked Sendable {
    let reader: AVAssetReader
    let writer: AVAssetWriter
    let videoInput: AVAssetWriterInput
    let videoOutput: AVAssetReaderOutput
    let audioInput: AVAssetWriterInput?
    let audioOutput: AVAssetReaderOutput?
    let totalSeconds: Double
    let progress: @Sendable (Double) -> Void

    init(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        videoInput: AVAssetWriterInput,
        videoOutput: AVAssetReaderOutput,
        audioInput: AVAssetWriterInput?,
        audioOutput: AVAssetReaderOutput?,
        totalSeconds: Double,
        progress: @escaping @Sendable (Double) -> Void
    ) {
        self.reader = reader
        self.writer = writer
        self.videoInput = videoInput
        self.videoOutput = videoOutput
        self.audioInput = audioInput
        self.audioOutput = audioOutput
        self.totalSeconds = totalSeconds
        self.progress = progress
    }

    func cancel() {
        reader.cancelReading()
        writer.cancelWriting()
    }

    func run() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let group = DispatchGroup()

            group.enter()
            videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "citrus.video")) { [self] in
                while videoInput.isReadyForMoreMediaData {
                    guard reader.status == .reading, let sample = videoOutput.copyNextSampleBuffer() else {
                        videoInput.markAsFinished()
                        group.leave()
                        return
                    }
                    let seconds = CMSampleBufferGetPresentationTimeStamp(sample).seconds
                    if seconds.isFinite { progress(min(0.99, seconds / totalSeconds)) }
                    if !videoInput.append(sample) {
                        videoInput.markAsFinished()
                        group.leave()
                        return
                    }
                }
            }

            if audioInput != nil, audioOutput != nil {
                group.enter()
                audioInput?.requestMediaDataWhenReady(on: DispatchQueue(label: "citrus.audio")) { [self] in
                    guard let input = audioInput, let output = audioOutput else { return }
                    while input.isReadyForMoreMediaData {
                        guard reader.status == .reading, let sample = output.copyNextSampleBuffer() else {
                            input.markAsFinished()
                            group.leave()
                            return
                        }
                        if !input.append(sample) {
                            input.markAsFinished()
                            group.leave()
                            return
                        }
                    }
                }
            }

            group.notify(queue: DispatchQueue(label: "citrus.finish")) { [self] in
                if reader.status == .failed {
                    continuation.resume(throwing: reader.error ?? ProcessingError.exportFailed)
                    return
                }
                if reader.status == .cancelled {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                writer.finishWriting {
                    switch self.writer.status {
                    case .completed: continuation.resume()
                    case .cancelled: continuation.resume(throwing: CancellationError())
                    default: continuation.resume(throwing: self.writer.error ?? ProcessingError.exportFailed)
                    }
                }
            }
        }
    }
}
