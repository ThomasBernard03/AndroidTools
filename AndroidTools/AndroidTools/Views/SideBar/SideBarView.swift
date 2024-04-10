//
//  SideBarView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct SideBarView: View {
    
    @StateObject var viewModel = SideBarViewModel()
    @State private var sideBarVisible = false

    
    var body: some View {
        
        NavigationSplitView {
            List {
                
                HStack {
                    Picker("", selection: $viewModel.selectedDeviceId) {
                        ForEach(viewModel.devices, id: \.self) { device in
                            Text(device.name).tag(device.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding([.leading], -14)
                    .padding([.trailing], -6)
                    
                    Spacer()

                     Button(action: viewModel.getAndroidDevices) {
                         Image(systemName: "arrow.clockwise")
                     }
                }
                
                NavigationLink(destination: InstallerView()) {
                    Label("Installer", systemImage: "app.badge")
                }
                
   
                
                NavigationLink(destination: InformationView()) {
                    Text("Informations")
                }
                
                NavigationLink(destination: FilesView()) {
                    Text("Files")
                }
                
                NavigationLink(destination: ScreenView()) {
                    Text("Screen")
                }

                
            }
            .listStyle(.sidebar)
        } detail: {
            
        }
        .onAppear {
            viewModel.getAndroidDevices()
        }
    }
}

#Preview {
    SideBarView()
}
