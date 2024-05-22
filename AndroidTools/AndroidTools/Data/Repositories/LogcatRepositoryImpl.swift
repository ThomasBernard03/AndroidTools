//
//  LogcatRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation
import os

class LogcatRepositoryImpl : LogcatRepository {

    private let shellHelper : ShellHelper = ShellHelper()
    private var buffer: String = ""
    private var lastLogcatPid : String = ""
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdbRepositoryImpl.self)
    )
    
    func getLogcat(deviceId : String, packageName : String = "", onResult: @escaping ([LogEntryModel]) -> Void) {
        buffer = "" // Reset buffer
        // First, clear logcat
        // clearLogcat(deviceId:deviceId)

        if packageName.isEmpty {
            if lastLogcatPid.isEmpty {
                getAllLogcat(deviceId: deviceId, onResult: onResult)
            }
            else {
                logger.debug("Already logging all logs")
            }
            
        }
        else {
            let pid = shellHelper.runAdbCommand("adb shell pidof '\(packageName)'")
            
            if pid.isEmpty {
                getAllLogcat(deviceId: deviceId, onResult: onResult)
            }
            else {
                let command = "adb -s \(deviceId) logcat -v threadtime --pid=\(pid)"
                shellHelper.runAdbCommand(command){ result in
                    self.buffer += result
                    onResult(self.processBuffer())
                }
            }
        }
    }
    
    private func getAllLogcat(deviceId : String,  onResult: @escaping ([LogEntryModel]) -> Void){
        let command = "adb -s \(deviceId) logcat -v threadtime"
        shellHelper.runAdbCommand(command){ result in
            self.buffer += result
            onResult(self.processBuffer())
        }
    }
    
    func clearLogcat(deviceId: String) {
        buffer = ""
        let _ = shellHelper.runAdbCommand("adb -s \(deviceId) logcat -c")
    }
    
    private func processBuffer() -> [LogEntryModel] {
        let lines = buffer.components(separatedBy: "\n")
        var logEntries : [LogEntryModel] = []
        
        for i in 0..<lines.count - 1 {
            if let logEntry = lines[i].toLogcatEntry() {
                logEntries.append(logEntry)
            }
        }
        
        buffer = lines.last ?? ""
        return logEntries
    }
}
