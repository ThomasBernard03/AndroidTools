//
//  InstallerViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

@Observable
final class InstallerViewModel: ObservableObject {
    
    var installStatus : InstallingApkStatus = .notStarted

    func installApk(deviceId : String, path : String){
        DispatchQueue.main.async {
            self.installStatus = .loading(fileName: path.substringAfterLast("/"))
        }
        
        
        print("Installing apk " + path)
        
        
        let result = AdbHelper().installApk(deviceId:deviceId,path: path)
        
        DispatchQueue.main.async {
            if result.hasSuffix("Success") {
                self.installStatus = .success
            }
            else {
                self.installStatus = .error(message: result)
            }
         }
    }
}
