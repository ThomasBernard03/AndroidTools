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
                        
                        if(viewModel.devices.isEmpty){
                            Text("No device connected")
                        }
                        else {
                            ForEach(viewModel.devices, id: \.self) { device in
                                Label(device.name, systemImage: "smartphone")
                                    .tag(device.id)
                                    .labelStyle(.titleAndIcon)
                            }
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
                
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.circle.fill")
                }
            }
            .listStyle(.sidebar)
            .onAppear {
                viewModel.getAndroidDevices()
            }
        } detail: {
            HomeView()
        }
    }
}

#Preview {
    SideBarView()
}
