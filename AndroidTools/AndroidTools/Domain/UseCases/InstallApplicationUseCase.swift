//
//  InstallApplicationUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation

class InstallApplicationUseCase {
    
    private let applicationRepository : ApplicationRepository = ApplicationRepositoryImpl()
    
    func execute(deviceId : String, path : String) -> Result<Void, InstallApplicationError> {
        let result = applicationRepository.installApplication(deviceId: deviceId, path: path)
        return result
    }
}
