//
//  GetLogcatUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation
import Combine

class GetLogcatUseCase {
    private let logcatRepository : LogcatRepository = LogcatRepositoryImpl()
    
    func execute(deviceId : String, 
                 packageName : String = "") -> AnyPublisher<[LogEntryModel], Never>{
        return logcatRepository.getLogcat(deviceId: deviceId, packageName: packageName)
    }
}
