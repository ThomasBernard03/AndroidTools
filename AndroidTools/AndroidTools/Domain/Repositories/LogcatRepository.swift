//
//  LogcatRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation
import Combine

protocol LogcatRepository {
    func getLogcat(deviceId : String, packageName : String) -> AnyPublisher<[LogEntryModel], Never>
    
    func clearLogcat(deviceId : String)
}
