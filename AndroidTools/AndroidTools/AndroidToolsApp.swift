//
//  AndroidToolsApp.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

@main
struct AndroidToolsApp: App {
    
    @AppStorage("mode") private var mode = "Automatic"
    
    var body: some Scene {
        WindowGroup {
            SideBarView()
                .frame(minWidth: 600, minHeight: 400)
                .preferredColorScheme(determineColorScheme(mode))
        }
        
        Settings {
            SettingsView()
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
