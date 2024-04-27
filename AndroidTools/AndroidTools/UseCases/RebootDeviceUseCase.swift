//
//  RebootDeviceUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation


class RebootDeviceUseCase {
    
    private let adbHelper = AdbHelper()
    
    func execute(deviceId : String) {
        let command = "-s \(deviceId) reboot"
        let result = adbHelper.runAdbCommand(command)
    }
}
