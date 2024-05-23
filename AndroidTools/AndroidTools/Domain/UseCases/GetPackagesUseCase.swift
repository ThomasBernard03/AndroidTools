//
//  GetPackagesUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 21/05/2024.
//

import Foundation

class GetPackagesUseCase {
    private let packageRepository : PackageRepository = PackageRepositoryImpl()
    
    func execute(deviceId : String) -> Result<[String], GetAllPackagesError> {
        let result = packageRepository.getAllPackages(deviceId: deviceId)
        return result
    }
}
