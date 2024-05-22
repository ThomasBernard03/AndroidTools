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
        // First, clear logcat
        let _ = shellHelper.runAdbCommand("adb -s \(deviceId) logcat -c")
        
        var command = ""
        
        if packageName.isEmpty {
            command = "adb -s \(deviceId) logcat -v threadtime"
        }
        else {
            let pid = shellHelper.runAdbCommand("adb shell pidof '\(packageName)'")
            command = "adb -s \(deviceId) logcat -v threadtime --pid=\(pid)"
        }
        
        
        shellHelper.runAdbCommand(command, outputHandler: onResult)
    }
}
