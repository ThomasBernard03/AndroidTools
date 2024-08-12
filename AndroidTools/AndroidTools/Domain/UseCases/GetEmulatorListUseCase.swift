//
//  GetEmulatorListUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/08/2024.
//

import Foundation

class GetEmulatorListUseCase {
    private let deviceRepository : DeviceRepository = DeviceRepositoryImpl()
    
    func execute() -> [DeviceListModel] {
        let devices = deviceRepository.getDevices()
        return devices
    }
}
