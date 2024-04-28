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
            VStack {
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
                        SideBarItem(label:"Home", systemImage: "house.fill")
                    }
                    
                    NavigationLink(
                        destination: InstallerView(deviceId: viewModel.selectedDeviceId)) {
                            SideBarItem(label: "App installer", systemImage: "app.badge")
                    }
                    .disabled(viewModel.devices.isEmpty)
                    
                    NavigationLink(destination: InformationView(deviceId: viewModel.selectedDeviceId)) {
                        SideBarItem(label:"Informations", systemImage: "info.circle")
                    }
                    .disabled(viewModel.devices.isEmpty)
                    
                    NavigationLink(destination: FilesView(deviceId: viewModel.selectedDeviceId)) {
                        SideBarItem(label:"Files", systemImage: "folder")
                    }
                    .disabled(viewModel.devices.isEmpty)
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.circle.fill")
                    }
                
                }
                .listStyle(SidebarListStyle())
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    HStack {
                        let appIcon = NSApplication.shared.applicationIconImage
                        Image(nsImage: appIcon!)
                            .resizable()
                            .scaledToFit()
                            .padding([.all], 6)
                        
                        
                        VStack(alignment: .leading) {
                            Text("Android Tools")
                                .fontWeight(.medium)
                            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                            Text(appVersion ?? "")
                                .font(.footnote)
                        }
                        
                        Spacer()
                    }
                    .frame(height: 60)
                    .frame(minWidth: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding()
                }
            }

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
