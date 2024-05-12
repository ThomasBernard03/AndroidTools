//
//  AndroidToolsApp.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI
import Sparkle

@main
struct AndroidToolsApp: App {
    
    @AppStorage("mode") private var mode = Constants.appearanceModes.first!
    private let updaterController : SPUStandardUpdaterController
    
    init(){
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        
        WindowGroup {
            SideBarView()
                .frame(minWidth: 600, minHeight: 400)
                .preferredColorScheme(determineColorScheme(mode))
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdateView(updater: updaterController.updater)
            }
        }
        
        Settings {
            SettingsView()
                .frame(width: 500, height: 200)
                .padding()
                .preferredColorScheme(determineColorScheme(mode))
        }
        
    }
    
    private func determineColorScheme(_ mode: String) -> ColorScheme? {
        switch mode {
            case "Dark":
                return .dark
            case "Light":
                return .light
            default:
                return nil
        }
    }
}
