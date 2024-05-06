//
//  InformationViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

@Observable
final class DeviceInformationViewModel: ObservableObject {
    var device : DeviceInformationModel? = nil
    
    private let getDeviceInformationUseCase = GetDeviceInformationUseCase()
    private let rebootDeviceUseCase = RebootDeviceUseCase()
    
    func getDeviceDetail(deviceId : String){
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.getDeviceInformationUseCase.execute(deviceId:deviceId)
            DispatchQueue.main.async {
                self.device = result
            }
        }
    }
    
    func rebootDevice(deviceId : String){
        rebootDeviceUseCase.execute(deviceId: deviceId)
    }
}
