//
//  InstallApplicationUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation

class InstallApplicationUseCase {
    
    private let adbHelper = AdbHelper()
    
    func execute(deviceId : String, path : String) -> String {
        let command = "-s \(deviceId) install \(path)"
        let result = adbHelper.runAdbCommand(command)
        
        return result
    }
}
