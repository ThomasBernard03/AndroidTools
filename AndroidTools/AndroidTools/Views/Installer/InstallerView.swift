//
//  InstallerView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers.UTType


struct InstallerView: View {
    
    let deviceId : String
    
    @State private var dropTargetted: Bool = false
    @ObservedObject private var viewModel = InstallerViewModel()
    
    
    private func loadApkFile(){
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.apk]
        panel.begin { (response) in
            if response == .OK, let url = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    viewModel.installApk(deviceId: deviceId, path: url.path)
                }
                
            }
        }
    }
    
    
    var body: some View {
        
        Text("Easily install an application on the connected phone using an .apk file")
        
        
        
        Image("AndroidApk")
            .resizable()
            .cornerRadius(44)
            .frame(width: 200, height: 200)
        
            .onDrop(of: [.apk], isTargeted: $dropTargetted) { providers in
                providers.first?.loadItem(forTypeIdentifier: UTType.apk.identifier, options: nil) { (item, error) in
                    
                    if let item = item as? URL {
                        let fileUrl = item.startAccessingSecurityScopedResource() ? item : URL(fileURLWithPath: item.path)
                        viewModel.installApk(deviceId: deviceId, path: fileUrl.path)
                        item.stopAccessingSecurityScopedResource()
                    }
                }
                
                
                return true
            }
            .overlay {
                if dropTargetted {
                    ZStack {
                        Color.black.opacity(0.5)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                            Text("Drop your apk here...")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(maxWidth: 250)
                        .multilineTextAlignment(.center)
                    }
                    .cornerRadius(44)
                }
                else {
                    Text("Click or drag .apk")
                        .foregroundStyle(.white)
                        .offset(CGSize(width: 0, height: 60.0))
                }
            }
            .animation(.default, value: dropTargetted)
            .padding()
            .onTapGesture {
                loadApkFile()
            }
        
        
        switch viewModel.installStatus {
        case .notStarted : Text("Not started")
        case .loading(let fileName) : ProgressView(){
            Text("Installing \(fileName)")
        }
        .progressViewStyle(.linear)
        .padding()
        case .success : Text("Apk installed")
        case .error(let message) : Text("Error \(message)")
                .foregroundStyle(.red)
        }
    }
        
}

#Preview {
    InstallerView(deviceId: "4dfda049")
}
