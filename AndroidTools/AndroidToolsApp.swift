import SwiftUI
import AppKit

@main
struct StocksMenuBarApp: App {
    @State var currentNumber: String = "1"
    
    var body: some Scene {
        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
            ContentView()
            Button("One") {
                currentNumber = "1"
            }
            Button("Two") {
                currentNumber = "2"
            }
            Button("Three") {
                currentNumber = "3"
            }
  
        }
        
      
    }
}
