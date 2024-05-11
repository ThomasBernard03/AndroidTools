//
//  GetAdbVersionUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/05/2024.
//

import Foundation

class GetAdbVersionUseCase {
    private let adbHelper : AdbHelper = AdbHelper()
    
    func execute() -> String {
        let result = adbHelper.runAdbCommand("version")
        return result
    }
}
