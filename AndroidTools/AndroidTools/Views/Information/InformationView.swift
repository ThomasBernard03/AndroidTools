//
//  InformationView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct InformationView: View {
    
    let deviceId : String
    
    @State private var viewModel = InformationViewModel()
    
    var body: some View {
        
        HStack{
            Image("Phone")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
            
            VStack {
                HStack {
                    Text(viewModel.device?.model.uppercased() ?? "-")
                        .font(.headline)
                        .textSelection(.enabled)
                    Spacer()
                }
                
                HStack {
                    Text("\(viewModel.device?.manufacturer ?? "-") -")
                        .textSelection(.enabled)
                    
                    Text(viewModel.device?.serialNumber ?? "")
                        .textSelection(.enabled)
                    
                    Text("\(String(viewModel.device?.batteryInfo.percentage ?? 0)) %")
                    

                    if viewModel.device?.batteryInfo.charging ?? false {
                        Image(systemName:"battery.100percent.bolt")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.gray, .gray, .green)
                            .font(.system(size: 16))
                    }
                    else {
                        Image(systemName:  (viewModel.device?.batteryInfo.percentage.toBatteryIcon()) ?? "battery.0percent")
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
    }
}

#Preview {
    InformationView(deviceId: "4dfda047")
}
