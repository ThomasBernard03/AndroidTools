//
//  ApplicationSettingsView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/05/2024.
//

import SwiftUI

struct ApplicationSettingsView: View {
    
    @StateObject private var viewModel = ApplicationSettingsViewModel()
    
    @AppStorage("adbPath") private var adbPath = "/usr/local/bin/adb"
    
    
    private func openFinderToSelectADB() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: adbPath)
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.adbPath = url.path
                viewModel.getAdbVersion()
            }
        }
    }
    
    
    var body: some View {
        Form {
            VStack(alignment:.center) {
                HStack {
                    if !viewModel.adbVersion.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    
                    Text("ADB version \(viewModel.adbVersion)")
                    Spacer()
                    Button("Check ADB version"){
                        viewModel.getAdbVersion()
                    }
                }
                
                HStack {
                    TextField("", text:$adbPath)
                        .disabled(true)
                        .padding(.leading, -10)
                    
                    Button("Change path"){
                        openFinderToSelectADB()
                    }
                }
                
                
                
                Spacer()
                
                Divider()
                
                
                HStack {
                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    Text("Android Tools v\(appVersion)")
                    
                    Spacer()
                    
                    Button("Check for updates"){
                        viewModel.checkForUpdates()
                    }
                }
                .padding(.top, 5)
            }
        }
        .onAppear {
            viewModel.getAdbVersion()
        }
    }
}

#Preview {
    ApplicationSettingsView()
}
