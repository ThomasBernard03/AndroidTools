//
//  LogcatRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation

class LogcatRepositoryImpl : LogcatRepository {
    
    private let shellHelper : ShellHelper = ShellHelper()
    
    func getLogcat(deviceId : String, packageName : String = "", onResult: @escaping (String) -> Void) {
        var command = ""
        var pid = shellHelper.runAdbCommand("adb shell pidof '\(packageName)'")
        
        if packageName.isEmpty {
            command = "adb -s \(deviceId) logcat -v threadtime"
        }
        else {
            command = "adb -s \(deviceId) logcat --pid=\(pid)"
        }
        
        
        shellHelper.runAdbCommand(command, outputHandler: onResult)
    }
}
