//
//  AdbRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation
import os

class AdbRepositoryImpl : AdbRepository {
    private var adbPath: String {
        UserDefaults.standard.string(forKey: "adbPath") ?? "/usr/local/bin/adb"
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdbRepositoryImpl.self)
    )
    
    func runAdbCommand(_ command: String) throws -> String {
        logger.info("Running command:\nadb \(command)")
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "\(adbPath) \(command)"]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        logger.info("Result:\n\(output)")
        return output
    }
    
    func getVersion() throws -> String {
        let result = try runAdbCommand("version")
        
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
