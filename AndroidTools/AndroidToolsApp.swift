import SwiftUI
import AppKit

@main
struct AndroidToolsApp: App {
    
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
