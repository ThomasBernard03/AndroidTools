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
    @State private var isHoveringPhone : Bool = false
    @State private var viewModel = InstallerViewModel()
    
    
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
        
        ZStack {
            VStack(spacing:20) {
                HStack {
                    Text("Install applications")
                        .font(.title)
                    Spacer()
                }
                
                HStack {
                    Text("You can easily install applications from an .apk file on your Mac. \nTo do this, you can use the file explorer or drag and drop an apk file.")
                    
                    Spacer()
                }
                
                Button {
                    loadApkFile()
                } label: {
                    Label("Open file explorer", systemImage: "folder")
                }
                
                Spacer()
            }
            .padding()
            .padding([.trailing], 100)
            .zIndex(1)
            
            HStack {
                Spacer()
                
                Image("ApplicationInstaller")
                    .resizable()
                    .scaledToFit()
                    .onHover { hovering in
                        isHoveringPhone = hovering
                    }
                    .offset(x: 50)
                    .frame(width: 300)
            }
            
            
            VStack {
                Spacer()
                
                switch viewModel.installStatus {
                case .loading(let fileName):
                    ProgressView {
                        Text("Intalling \(fileName)")
                            .padding([.horizontal])
                    }
                    .progressViewStyle(LinearProgressViewStyle())
                    .offset(y:7)
                case .success:
                    Text("Install sucess")
                        .padding()
                case .error(let message):
                    Text("Error: \(message)")
                        .foregroundStyle(.red)
                        .padding()
                case .notStarted:
                    EmptyView()
                }
                
    
            }
        }
        
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
                    .multilineTextAlignment(.center)
                }
            }
        }
        .animation(.default, value: dropTargetted)
        .navigationTitle("Application installer")
        

        

        
    }
}

#Preview {
    InstallerView(deviceId: "4dfda049")
}
