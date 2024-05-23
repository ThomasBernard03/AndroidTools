//
//  LogcatRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation
import os
import Combine

class LogcatRepositoryImpl : LogcatRepository {

    private let shellHelper : ShellHelper = ShellHelper()
    private var buffer: String = ""
    private var lastLogcatPid : String = ""
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdbRepositoryImpl.self)
    )
    
    func getLogcat(deviceId : String, packageName : String = "") -> AnyPublisher<[LogEntryModel], Never> {
        let subject = PassthroughSubject<[LogEntryModel], Never>()
        buffer = "" // Reset buffer

        if packageName.isEmpty {
            if lastLogcatPid.isEmpty {
                getAllLogcat(deviceId: deviceId)
                    .sink { logEntries in
                        subject.send(logEntries)
                    }
            } else {
                logger.debug("Already logging all logs")
            }
        } else {
            let pid = shellHelper.runAdbCommand("adb shell pidof '\(packageName)'")
            if pid.isEmpty {
                getAllLogcat(deviceId: deviceId)
                    .sink { logEntries in
                        subject.send(logEntries)
                    }
            } else {
                let command = "adb -s \(deviceId) logcat -v threadtime --pid=\(pid)"
                shellHelper.runAdbCommandCombine(command)
                    .sink { result in
                        self.buffer += result
                        subject.send(self.processBuffer())
                    }
            }
        }

        return subject.eraseToAnyPublisher()
    }
    
    private func getAllLogcat(deviceId : String) -> AnyPublisher<[LogEntryModel], Never> {
        let command = "adb -s \(deviceId) logcat -v threadtime"
        return shellHelper.runAdbCommandCombine(command)
            .map { result in
                self.buffer += result
                return self.processBuffer()
            }
            .eraseToAnyPublisher()
    }
    
    func clearLogcat(deviceId: String) {
        buffer = ""
        let _ : String = shellHelper.runAdbCommand("adb -s \(deviceId) logcat -c")
    }
    
    private func processBuffer() -> [LogEntryModel] {
        let lines = buffer.components(separatedBy: "\n")
        var logEntries: [LogEntryModel] = []
        
        for i in 0..<lines.count - 1 {
            if let logEntry = lines[i].toLogcatEntry() {
                logEntries.append(logEntry)
            }
        }
        
        buffer = lines.last ?? ""
        return logEntries
    }
}
