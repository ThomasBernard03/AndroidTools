//
//  LogcatRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation

protocol LogcatRepository {
    func getLogcat(deviceId : String, onResult: @escaping (String) -> Void)
}
