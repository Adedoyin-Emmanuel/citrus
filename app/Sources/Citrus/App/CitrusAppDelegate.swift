import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class CitrusAppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore: SettingsStore
    let queueViewModel: QueueViewModel

    private let notificationCenter: CitrusNotificationCenter
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: Any?

    override init() {
        let settings = SettingsStore()
        let notificationCenter = CitrusNotificationCenter()
        let processor = MediaOptimizer()

        self.notificationCenter = notificationCenter

        self.settingsStore = settings
        self.queueViewModel = QueueViewModel(
            processor: processor,
            notificationCenter: notificationCenter,
            settingsStore: settings
        )
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()

        super.init()

        self.queueViewModel.onImportCompleted = { [weak self] in
            self?.showPopover()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePopover()

        UNUserNotificationCenter.current().delegate = self
        Task { await notificationCenter.requestAuthorizationIfNeeded() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "circle.hexagongrid.fill", accessibilityDescription: "Citrus")
        button.image?.isTemplate = true
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 440, height: 500)
        popover.contentViewController = NSHostingController(
            rootView: DashboardView()
                .environmentObject(queueViewModel)
                .environmentObject(settingsStore)
        )

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                if self?.queueViewModel.hasPendingConfiguration == true {
                    return
                }
                self?.closePopover()
            }
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}

extension CitrusAppDelegate: UNUserNotificationCenterDelegate {
    // Menu bar apps count as "foreground", so without this the completion banner
    // is silently suppressed. Present it as a banner with sound regardless.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
