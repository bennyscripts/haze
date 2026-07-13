import SwiftUI
import Foundation
import Network
import UserNotifications
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var version = "1.2.0"
    var statusItem: NSStatusItem?
    var geoIP: IPGeoIP? = IPGeoIP()
    
    var welcomeWindow: NSWindow?
    var lookupPopover = NSPopover()
    var recentsPopover = NSPopover()
    var lookupView: LookupView?
    
    let lookupController = LookupController()
    
    @Published var recents = RecentsManager()
    private var recentsCancellable: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        recentsCancellable = recents.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        
        if GeoDatabaseManager.shared.databasesExist() {
            geoIP = IPGeoIP()

            if GeoDatabaseManager.shared.shouldUpdate() {

                GeoDatabaseManager.shared.updateDatabases { success in

                    if success {
                        self.geoIP = IPGeoIP()
                        print("Geo databases updated")
                    }
                }
            }
        } else {
            GeoDatabaseManager.shared.updateDatabases { success in

                if success {
                    self.geoIP = IPGeoIP()
                    print("Geo databases downloaded")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.showWelcome()
        }
        
        let lookupView = LookupView(
            appDelegate: self,
            controller: lookupController,
            autoLookup: false,
            addToRecents: true
        )
        
        lookupPopover.contentViewController = NSViewController()
        lookupPopover.contentViewController?.view = NSHostingView(rootView: lookupView)
        lookupPopover.behavior = .transient
        lookupPopover.animates = true
        lookupPopover.contentSize = NSSize(width: 380, height: 300)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenuBarMenu()
        
        guard let logo = NSImage(named: NSImage.Name("menu-bar")) else { return }

        let resizedLogo = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { (dstRect) -> Bool in
            logo.draw(in: dstRect)
            return true
        }
        
        if let MenuButton = statusItem?.button {
//            MenuButton.action = #selector(openMenu)
            MenuButton.image = resizedLogo
            MenuButton.image?.isTemplate = true
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }
    
    func lookupIP(_ ip: String) {
        lookupController.requestedIP = ip

        guard let button = statusItem?.button else { return }

        lookupPopover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
    }
    
    @objc
    func showRecents() {
        guard let button = statusItem?.button else { return }

        NSApp.activate(ignoringOtherApps: true)

        let recentsView = RecentsView(appDelegate: self)
        
        recentsPopover.contentViewController = NSViewController()
        recentsPopover.contentViewController?.view = NSHostingView(rootView: recentsView)
        recentsPopover.behavior = .transient
        recentsPopover.animates = true
        recentsPopover.contentSize = NSSize(width: 380, height: 300)
        
        recentsPopover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        
        DispatchQueue.main.async {
            self.recentsPopover.contentViewController?.view.window?.makeKey()
            self.recentsPopover.contentViewController?.view.window?.makeFirstResponder(nil)
        }
    }
    
    func showWelcome() {
        let view = WelcomeView(appDelegate: self)
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(
            contentViewController: controller
        )

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 550))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true

        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = true

        window.center()

        window.isReleasedWhenClosed = false

        welcomeWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func showCopiedNotification(type: String) {
        let content = UNMutableNotificationContent()
        content.title = "Haze"
        content.body = "\(type) copied to clipboard"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func openMenu() {
        guard let button = statusItem?.button else { return }

        NSApp.activate(ignoringOtherApps: true)

        lookupPopover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
    }
    
    @objc func copyPublicIP() {
        let url = URL(string: "https://api.ipify.org")!

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard
                let data = data,
                let ip = String(data: data, encoding: .utf8),
                error == nil
            else {
                return
            }

            DispatchQueue.main.async {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ip, forType: .string)

                self.showCopiedNotification(type: "Public IP")
            }
        }.resume()
    }


    @objc func copyLocalIP() {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var pointer = ifaddr

            while let interface = pointer {
                defer {
                    pointer = interface.pointee.ifa_next
                }

                let name = String(cString: interface.pointee.ifa_name)

                // en0 = WiFi, en1 = ethernet on most Macs
                if name == "en0" || name == "en1" {
                    let addr = interface.pointee.ifa_addr.pointee

                    if addr.sa_family == UInt8(AF_INET) {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

                        getnameinfo(
                            &interface.pointee.ifa_addr.pointee,
                            socklen_t(addr.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        )

                        address = String(cString: hostname)
                        break
                    }
                }
            }

            freeifaddrs(ifaddr)
        }

        if let address = address {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(address, forType: .string)

            showCopiedNotification(type: "Local IP")
        }
    }
    
    func setupMenuBarMenu() {
        let menu = NSMenu()

        let lookupIP = NSMenuItem(
            title: "Lookup",
            action: #selector(openMenu),
            keyEquivalent: ""
        )
        
        let copyPublicIP = NSMenuItem(
            title: "Copy Public IP",
            action: #selector(copyPublicIP),
            keyEquivalent: ""
        )

        let copyLocalIP = NSMenuItem(
            title: "Copy Local IP",
            action: #selector(copyLocalIP),
            keyEquivalent: ""
        )

        let recents = NSMenuItem(
            title: "Recents",
            action: #selector(showRecents),
            keyEquivalent: ""
        )
        
        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )

        menu.addItem(lookupIP)
        menu.addItem(recents)
        menu.addItem(.separator())
        menu.addItem(copyPublicIP)
        menu.addItem(copyLocalIP)
        menu.addItem(.separator())
        menu.addItem(quit)

        statusItem?.menu = menu
    }
}
