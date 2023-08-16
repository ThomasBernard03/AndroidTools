//
//  ContentView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct ContentView: View {
    
    let adb: AdbHelper = AdbHelper()
    
    @State private var selectedDevice: Device? = nil
    @State private var selectedDeviceName : String = ""
    
    var body: some View {
        DispatchQueue.global(qos: .background).async {
            selectedDevice = adb.getDevices().first
            
            if let device = selectedDevice {
                selectedDeviceName = adb.getDeviceName(deviceId: device.id)
            }
            
            
        }
        
        return VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
