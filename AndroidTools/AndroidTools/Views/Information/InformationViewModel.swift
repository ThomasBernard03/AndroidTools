//
//  InformationViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

@Observable
final class InformationViewModel: ObservableObject {
    var device : DeviceDetail? = nil
    
    
    func getDeviceDetail(deviceId : String){
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AdbHelper().getDeviceInformation(deviceId:deviceId)
            DispatchQueue.main.async {
                self.device = result
            }
        }
        
    }
}
