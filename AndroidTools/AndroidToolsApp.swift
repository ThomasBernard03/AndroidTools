import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    let adbHelper = AdbHelper()

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { url in
            print("APK file opened: \(url)")
            let result = adbHelper.installApk(path: url.path())
            sendNotification(title: "Installation Started", message: result)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApplication.shared.terminate(nil)
        }
    }
}

func sendNotification(title: String, message: String) {
    let notification = NSUserNotification()
    notification.title = title
    notification.informativeText = message
    NSUserNotificationCenter.default.deliver(notification)
}

@main
struct StocksMenuBarApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var currentNumber: String = "1"
    
    var body: some Scene {
        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
            ContentView()
            Button("Quit"){
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
