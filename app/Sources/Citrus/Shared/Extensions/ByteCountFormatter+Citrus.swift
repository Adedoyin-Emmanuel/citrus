import Foundation

extension Int64 {
    var citrusFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension Int {
    var citrusDuration: String {
        if self < 60 { return "\(self)s left" }
        return "\(self / 60)m \(self % 60)s left"
    }
}
