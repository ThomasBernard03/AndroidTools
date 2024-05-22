//
//  LogcatRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/05/2024.
//

import Foundation

protocol LogcatRepository {
    func getLogcat(deviceId : String, packageName : String, onResult: @escaping (String) -> Void)
}
