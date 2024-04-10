//
//  InstallerView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers.UTType


struct InstallerView: View {
    
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
                    viewModel.installApk(path: url.path)
                }
                
            }
        }
    }
    
    
    var body: some View {
        
        
        
        RoundedRectangle(cornerRadius: 20)
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .frame(width: 200, height: 200)
        
            .onDrop(of: [.apk], isTargeted: $dropTargetted) { providers in
                providers.first?.loadItem(forTypeIdentifier: UTType.apk.identifier, options: nil) { (item, error) in
                    
                    if let item = item as? URL {
                        let fileUrl = item.startAccessingSecurityScopedResource() ? item : URL(fileURLWithPath: item.path)
                        viewModel.installApk(path: fileUrl.path)
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
                    .cornerRadius(20)
                }
            }
            .animation(.default, value: dropTargetted)
            .padding()
        
        
        Button {
            loadApkFile()
            
        } label: {
            Text("Open file explorer")
        }
        
        switch viewModel.installStatus {
        case .notStarted : Text("Not started")
        case .loading(let fileName) : Text("Loading " + fileName)
        case .success : Text("Apk installed")
        case .error(let message) : Text("Error " + message)
        }
    }
        
}

#Preview {
    InstallerView()
}
