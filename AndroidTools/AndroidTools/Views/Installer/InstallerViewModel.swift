//
//  InstallerViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

@Observable
final class InstallerViewModel: ObservableObject {
    var toast : Toast? = nil
    
    private let installApplicationUseCase = InstallApplicationUseCase()

    func installApk(deviceId : String, path : String){
        let fileName = path.substringAfterLast("/")
        self.toast = Toast(style: .loading, message: "Installing \(fileName)")
        
        let result = installApplicationUseCase.execute(deviceId: deviceId, path: path)
        
        if result.hasSuffix("Success") {
            self.toast = Toast(style: .success, message: "Installation of \(fileName) completed successfully", width: .infinity)
        }
        else {
            self.toast = Toast(style: .error, message: "Error during installation of \(fileName) :\n\(result)", width: .infinity)
        }
    }
}
