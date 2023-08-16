//
//  ContentView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct ContentView: View {
    
    private let adb: AdbHelper = AdbHelper()
    
    @State private var availableDevices : [Device] = []
    @State private var selectedDevice : Device? = nil
    
    let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0"
    
    
    var body: some View {
        
        HStack {
            // Left pannel
            VStack {
                HStack {
                    Picker("", selection: $selectedDevice) {
                        ForEach(availableDevices) { device in
                            Text(device.name)
                        }
                    }
                    .pickerStyle(.automatic)
                    
                    Spacer()
                    
                    Button {
                        DispatchQueue.global(qos: .background).async {
                            availableDevices = adb.getDevices()
                            //selectedDevice = availableDevices.first
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }

                }
                .padding(.bottom, 40)
                
                
                SideBarView()
                
                
                Spacer()
                
                Text(version)

            }
            .frame(width: 250)
            
            
            
            // Content
            VStack {
                FilesView()
                
                HStack {
                    Spacer()
                }
            }
            .frame(minWidth: 300)
        }
        
        
        
        .padding()
        .background(Color("Background"))
        
        .onAppear {
            DispatchQueue.global(qos: .background).async {
                availableDevices = adb.getDevices()
                selectedDevice = availableDevices.first
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
