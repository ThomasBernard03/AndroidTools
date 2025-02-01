//
//  InstallingViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 01/02/2025.
//

import Foundation

extension InstallingView {
    @Observable
    class ViewModel {
        private let logger = AppLogger()
        private let adbHelper = AdbHelper()
        
        var applicationName : String = ""
        var message : String = ""
        
        
        func installApk(path : URL) async {
            applicationName = path.lastPathComponent 
            let result = adbHelper.installApk(path: path)
            message = result
        }
    }
}
