//
//  GetConnectedDeviceListUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

class GetConnectedDeviceListUseCase {
    
    private let deviceRepository : DeviceRepository = DeviceRepositoryImpl()
    
    func execute() -> [DeviceListModel] {
        let devices = deviceRepository.getDevices()
        return devices
    }
}
