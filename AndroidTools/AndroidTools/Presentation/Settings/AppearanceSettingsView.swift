//
//  AppearanceSettingsView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/05/2024.
//

import SwiftUI

struct AppearanceSettingsView: View {
    
    @AppStorage("mode") private var mode = Constants.appearanceModes.first!
    private let appIcons: [String] = ["AppIconDark", "AppIconLight", "AppIconAndroid"]
    @AppStorage("appIconName") private var appIconName = "AppIconDark"
    
    var body: some View {
        Form {
            Picker("Appearance", selection: $mode) {
                ForEach(Constants.appearanceModes, id: \.self) { mode in
                    Text(mode)
                    if mode == Constants.appearanceModes.first {
                        Divider()
                    }
                    
                }
            }
            
            Text("Change application icon ")
            
            HStack {
                ForEach(appIcons, id: \.self) { name in
                    VStack {
                        Image(nsImage: NSImage(named: name)!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60) // Highlight the selected icon
                    }
                
                    .background(appIconName == name ? Color.accentColor : Color.clear)
                    .cornerRadius(13)

                    .onTapGesture {
                        NSApplication.shared.applicationIconImage = NSImage(named: name)
                        appIconName = name  // Update the selected icon
                    }
                }
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
