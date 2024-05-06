//
//  RebootDeviceUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation


class RebootDeviceUseCase {
    
    private let deviceRepository : DeviceRepository = DeviceRepositoryImpl()
    
    func execute(deviceId : String) {
        deviceRepository.rebootDevice(deviceId: deviceId)
    }
}
