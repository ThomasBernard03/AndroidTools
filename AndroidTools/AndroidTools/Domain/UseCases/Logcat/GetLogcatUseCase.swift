//
//  GetLogcatUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation
import Combine

class GetLogcatUseCase {
    private let logcatRepository : LogcatRepositoryImpl = LogcatRepositoryImpl()
    private let adbRepository : AdbRepositoryImpl = AdbRepositoryImpl()
    
    func execute(deviceId : String, packageName : String = "") -> AnyPublisher<[LogEntryModel], Never>{
        if packageName.isEmpty {
            let command = "-s \(deviceId) logcat -v threadtime"
            return adbRepository.runAdbCommandCombine(command)
                .map { raw in
                    self.logcatRepository.buffer += raw
                    return self.logcatRepository.processBuffer()
                }.eraseToAnyPublisher()
        }
        else {
            let pid = try? adbRepository.runAdbCommand("shell pidof '\(packageName)'")
            let command = "-s \(deviceId) logcat -v threadtime --pid=\(pid ?? "")"
            return adbRepository.runAdbCommandCombine(command)
                .map { raw in
                    self.logcatRepository.buffer += raw
                    return self.logcatRepository.processBuffer()
                }.eraseToAnyPublisher()
        }
    }
}
