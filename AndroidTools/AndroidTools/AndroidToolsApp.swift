//
//  AndroidToolsApp.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

@main
struct AndroidToolsApp: App {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            SideBarView()
                .frame(minWidth: 600, minHeight: 400)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        
        Settings {
            SettingsView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        
    }
}
