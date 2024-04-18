//
//  SideBarView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct SideBarView: View {
    
    @ObservedObject var viewModel = SideBarViewModel()

    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        
        
        
        if viewModel.devices.isEmpty {
            NoDeviceConnectedView() {
                viewModel.getAndroidDevices()
            }
            .onAppear {
                viewModel.getAndroidDevices()
            }
        }
        else {
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
                    
                    NavigationLink(
                        destination: InstallerView(deviceId: viewModel.selectedDeviceId)) {
                        Label("Installer", systemImage: "app.badge")

                    }
                    
                    NavigationLink(destination: InformationView(deviceId: viewModel.selectedDeviceId)) {
                        Label("Informations", systemImage: "info.circle")

                    }
                    
                    NavigationLink(destination: FilesView(deviceId: viewModel.selectedDeviceId)) {
                        Label("Files", systemImage: "folder")

                    }
                    
                    NavigationLink(destination: ScreenView()) {
                        Label("Screen", systemImage: "smartphone")

                    }
                    
                    HStack{
                         Toggle("Dark Mode", isOn: $isDarkMode)
                       }

                    
                }
                .listStyle(.sidebar)
            } detail: {
                Text("Hello")
                    .id(viewModel.selectedDeviceId)
            }
        }
        

    }
}

#Preview {
    SideBarView()
}
