//
//  ApplicationRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

protocol ApplicationRepository {
    
    /**
     Installs an application on a specified device.
     
     - Parameters:
        - deviceId: The unique identifier of the device on which to install the application.
        - path: The .apk file path on the mac
     
     - Returns: A `Result<Void, Error>` indicating the success or failure of the installation process.
     */
    func installApplication(deviceId : String, path : String) -> Result<Void, InstallApplicationError>
}
