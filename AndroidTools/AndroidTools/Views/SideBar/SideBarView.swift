//
//  SideBarView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct SideBarView: View {
    
    @State var viewModel = SideBarViewModel()
    
    var body: some View {
        
        NavigationSplitView {
            VStack {
                List {
                    HStack {
                        Menu(viewModel.selectedDevice?.name ?? "") {
                            Text("\(viewModel.devices.count) device(s) connected")
                            
                            Divider()
                            
                            ForEach(viewModel.devices, id: \.self) { device in
                                
                                Button {
                                    viewModel.selectedDevice = device
                                } label: {
                                    Label(device.name, systemImage: "smartphone")
                                        .labelStyle(.titleAndIcon)
                                }
                            }
                        }
                        
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
                        destination: InstallerView(deviceId: viewModel.selectedDevice?.id ?? "")) {
                            SideBarItem(label: "App installer", systemImage: "app.badge")
                    }
                    .disabled(viewModel.devices.isEmpty)
                    
                    NavigationLink(destination: InformationView(deviceId: viewModel.selectedDevice?.id ?? "")) {
                        SideBarItem(label:"Informations", systemImage: "info.circle")
                    }
                    .disabled(viewModel.devices.isEmpty)
                    
                    NavigationLink(destination: FilesView(deviceId: viewModel.selectedDevice?.id ?? "")) {
                        SideBarItem(label:"Files", systemImage: "folder")
                    }
                    .disabled(viewModel.devices.isEmpty)
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        SideBarItem(label:"Settings", systemImage: "gearshape.circle")
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
