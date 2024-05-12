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
        
        let lines = result.split(separator: "\n")
        
        // Find the line that starts with "Version"
        if let versionLine = lines.first(where: { $0.starts(with: "Version") }) {
            
            let version = versionLine
                .replacingOccurrences(of: "Version ", with: "")
                .split(separator: " ")
                .first ?? ""
            return String(version)
        }
        
        return ""
    }
}
