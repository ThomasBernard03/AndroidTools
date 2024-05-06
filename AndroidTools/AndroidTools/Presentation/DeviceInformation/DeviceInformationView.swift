//
//  InformationView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct DeviceInformationView: View {
    
    let deviceId : String
    
    @State private var viewModel = DeviceInformationViewModel()
    @State private var isPresentingRebootConfirmation: Bool = false

    
    var body: some View {
        
        HStack{
            Image("GenericPhone")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
            
            VStack {
                HStack {
                    Text(viewModel.device?.model.uppercased() ?? "")
                        .font(.headline)
                        .textSelection(.enabled)
                    Spacer()
                }
                
                HStack {
                    Text(viewModel.device?.manufacturer ?? "")
                        .textSelection(.enabled)
                    
                    Text("-")
                    
                    Text(viewModel.device?.serialNumber ?? "")
                        .textSelection(.enabled)
                    
                    Text("\(String(viewModel.device?.batteryInformation.percentage ?? 0))%")
                    

                    if viewModel.device?.batteryInformation.charging ?? false {
                        Image(systemName:"battery.100percent.bolt")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.gray, .gray, .green)
                            .font(.system(size: 16))
                    }
                    else {
                        Image(systemName:  (viewModel.device?.batteryInformation.percentage.toBatteryIcon()) ?? "battery.0percent")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, .gray)
                            .font(.system(size: 16))
                    }
                    
                    Spacer()
                }
            }
                
                
        }
        .padding()
        .onAppear {
            viewModel.getDeviceDetail(deviceId: deviceId)
        }
        .onChange(of: deviceId) { oldValue, newValue in
            viewModel.getDeviceDetail(deviceId: newValue)
        }
        
        List {
            Section(header: Text("General informations")) {
                HStack{
                    Text("Android version")
                    Spacer()
                    Text(viewModel.device?.androidVersion ?? "")
                }
                
                HStack{
                    Text("Manufacturer")
                    Spacer()
                    Text(viewModel.device?.manufacturer ?? "")
                }
                
                HStack{
                    Text("Model")
                    Spacer()
                    Text(viewModel.device?.model ?? "")
                }
            }
        }
        .toolbar {
            Button {isPresentingRebootConfirmation.toggle()} label: {
                Label("Reboot device", systemImage: "arrow.circlepath")
            }
        }
        .confirmationDialog("Reboot connected device ?",
          isPresented: $isPresentingRebootConfirmation) {
          Button("Confirm", role: .destructive) {
              viewModel.rebootDevice(deviceId: deviceId)
          }
        }
    }
}

#Preview {
    DeviceInformationView(deviceId: "4dfda047")
}
