//
//  InstallApplicationUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation

class InstallApplicationUseCase {
    
    private let packageRepository : PackageRepository = PackageRepositoryImpl()
    
    func execute(deviceId : String, path : String) -> Result<Void, InstallApplicationError> {
        let result = packageRepository.installApplication(deviceId: deviceId, path: path)
        return result
    }
}
