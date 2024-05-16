//
//  ShellHelper.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation
import os

class ShellHelper {
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdbRepositoryImpl.self)
    )
    
    func runAdbCommand(_ command: String) -> String {
        logger.info("Running command:\n\(command)")
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        logger.info("Result:\n\(output)")
        return output
    }
}
