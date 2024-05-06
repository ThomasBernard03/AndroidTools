//
//  ApplicationRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

class ApplicationRepositoryImpl : ApplicationRepository {
    
    private let adbHelper : AdbHelper = AdbHelper()
    
    func installApplication(deviceId : String, path : String) -> Result<Void, InstallApplicationError> {
        let command = "-s \(deviceId) install \(path)"
        let result = adbHelper.runAdbCommand(command)
        
        if result.contains("Success") {
            return .success(Void())
        }
        else {
            if result.contains("INSTALL_FAILED_VERSION_DOWNGRADE"){
                return .failure(InstallApplicationError.versionDowngradeError)
            }
            else {
                return .failure(InstallApplicationError.unknownError(result))
            }
        }
    }
}
