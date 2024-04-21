//
//  SideBarView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct SideBarView: View {
    
    @ObservedObject var viewModel = SideBarViewModel()
    
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
                .padding([.bottom], 10)
                
                NavigationLink(destination: HomeView()) {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationLink(
                    destination: InstallerView(deviceId: viewModel.selectedDeviceId)) {
                    Label("Installer", systemImage: "app.badge")
                }
                .disabled(viewModel.devices.isEmpty)
                
                NavigationLink(destination: InformationView(deviceId: viewModel.selectedDeviceId)) {
                    Label("Informations", systemImage: "info.circle")
                }
                .disabled(viewModel.devices.isEmpty)
                
                NavigationLink(destination: FilesView(deviceId: viewModel.selectedDeviceId)) {
                    Label("Files", systemImage: "folder")
                }
                .disabled(viewModel.devices.isEmpty)
                
                NavigationLink(destination: ScreenView()) {
                    Label("Screen", systemImage: "smartphone")
                }
                .disabled(viewModel.devices.isEmpty)
                
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.circle.fill")
                }

                
                
                
            }
            .listStyle(.sidebar)
        } detail: {
            HomeView()
        }
    }
}

#Preview {
    SideBarView()
}
