//
//  SettingsView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 19/04/2024.
//

import SwiftUI

struct SettingsView: View {
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView {
            VStack{
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag(Tabs.general)
            VStack {
                
            }
            .tabItem {
                Label("Advanced", systemImage: "star")
            }
            .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

#Preview {
    SettingsView()
}
