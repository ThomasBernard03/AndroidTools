//
//  GetLogcatUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation

class GetLogcatUseCase {
    private let logcatRepository : LogcatRepository = LogcatRepositoryImpl()
    
    func execute(deviceId : String, 
                 packageName : String = "",
                 onResult: @escaping ([LogEntryModel]) -> Void) {
        logcatRepository.getLogcat(deviceId: deviceId, packageName: packageName, onResult: onResult)
    }
}
