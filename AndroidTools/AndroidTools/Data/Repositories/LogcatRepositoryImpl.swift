//
//  LogcatRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation

class LogcatRepositoryImpl : LogcatRepository {
    
    private let shellHelper : ShellHelper = ShellHelper()
    
    func getLogcat(deviceId : String, onResult: @escaping (String) -> Void) {
        let command = "adb -s \(deviceId) logcat -v threadtime"
        shellHelper.runAdbCommand(command, outputHandler: onResult)
    }
}
