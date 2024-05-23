//
//  ApplicationRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

class PackageRepositoryImpl : PackageRepository {

    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    func installApplication(deviceId : String, path : String) -> Result<Void, InstallApplicationError> {
        let command = "-s \(deviceId) install \(path)"
        let result = try? adbRepository.runAdbCommand(command)
        
        if result?.contains("Success") ?? false {
            return .success(Void())
        }
        else {
            if result?.contains("INSTALL_FAILED_VERSION_DOWNGRADE") ?? false{
                return .failure(InstallApplicationError.versionDowngradeError)
            }
            else {
                return .failure(InstallApplicationError.unknownError(result ?? "error"))
            }
        }
    }
    
    func getAllPackages(deviceId : String) -> Result<[String], GetAllPackagesError> {
        let command = "-s \(deviceId) shell cmd package list packages"
        let result = try? adbRepository.runAdbCommand(command)
        
        if !(result?.isEmpty ?? true) {
            let packages = result!.replacingOccurrences(of: "package:", with: "").split(separator: "\n").map({ sub in
                String(sub)
            })
            return .success(packages)
        }
        else {
            return .failure(.unknownError("error"))
        }
    }
}
