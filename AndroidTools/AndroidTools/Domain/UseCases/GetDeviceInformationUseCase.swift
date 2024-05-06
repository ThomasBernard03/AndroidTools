//
//  GetDeviceInformationUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation

class GetDeviceInformationUseCase {
    
    private let deviceRepository : DeviceRepository = DeviceRepositoryImpl()
    
    func execute(deviceId : String) -> DeviceInformationModel {
        let deviceInformation = deviceRepository.getDevice(deviceId: deviceId)
        return deviceInformation
    }
}
