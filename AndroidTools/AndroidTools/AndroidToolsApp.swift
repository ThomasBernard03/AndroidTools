//
//  AndroidToolsApp.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

@main
struct AndroidToolsApp: App {
    
    @AppStorage("mode") private var mode = false
    
    var body: some Scene {
        WindowGroup {
            SideBarView()
                .frame(minWidth: 600, minHeight: 400)
                .preferredColorScheme(.light)
        }
        
        Settings {
            SettingsView()
                .padding()
                .preferredColorScheme(.dark)
        }
        
    }
}
