//
//  InformationView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct InformationView: View {
    
    @ObservedObject private var viewModel = InformationViewModel()
    
    var body: some View {
        
        HStack{
            Image("Phone")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
            
            VStack {
                HStack {
                    Text(viewModel.device?.serialNumber ?? "-")
                        .font(.headline)
                        .textSelection(.enabled)
                    Spacer()
                }
                
                HStack {
                    Text("\(viewModel.device?.manufacturer ?? "-") \(viewModel.device?.model ?? "-")")
                        .textSelection(.enabled)
                    
                    Text("\(String(viewModel.device?.batteryInfo.percentage ?? 0)) %")
                    
                    Image(systemName:  (viewModel.device?.batteryInfo.percentage.toBatteryIcon(charging: viewModel.device?.batteryInfo.charging ?? false)) ?? "battery.0percent")
                    
                    Spacer()
                }
            }
                
                
        }
        .padding()
        .onAppear {
            viewModel.getDeviceDetail()
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
    InformationView()
}
