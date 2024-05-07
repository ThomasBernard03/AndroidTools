//
//  InstallerViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

@Observable
final class InstallApplicationViewModel: ObservableObject {
    var toast : Toast? = nil
    
    private let installApplicationUseCase = InstallApplicationUseCase()

    func installApk(deviceId : String, path : String){
        let fileName = path.substringAfterLast("/")
        self.toast = Toast(style: .loading, message: "Installing \(fileName)")
        
        let result = installApplicationUseCase.execute(deviceId: deviceId, path: path)
        
        switch(result){
        case .success: 
            self.toast = Toast(style: .success, message: "Installation of \(fileName) completed successfully")
            break
        case .failure(let error):
            manageError(applicationName: fileName, error: error)
            break
        }
    }
    
    private func manageError(applicationName : String, error : InstallApplicationError){
        switch(error){
        case .versionDowngradeError:
            self.toast = Toast(style: .error, message: "Error during installation of \(applicationName) :\nA newer version is already installed")
            break
        case .unknownError(let message):
            self.toast = Toast(style: .error, message: "Error during installation of \(applicationName) :\n\(message)")
            break
        }
    }
}
