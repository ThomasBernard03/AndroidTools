//
//  ClearLogcatUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 22/05/2024.
//

import Foundation

class ClearLogcatUseCase {
    private let logcatRepository : LogcatRepository = LogcatRepositoryImpl()
    
    func execute(deviceId : String) {
        logcatRepository.clearLogcat(deviceId: deviceId)
    }
}
