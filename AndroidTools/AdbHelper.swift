//
//  AdbHelper.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

class AdbHelper {
    
    let adb = Bundle.main.url(forResource: "adb", withExtension: nil)
    
    init() {
        _ = runAdbCommand("root")
    }
    
    
    func installApk(path : URL) -> String {
        let command = "install \(path)"
        return runAdbCommand(command)
    }
    
    private func runAdbCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "\(adb!.path) \(command)"]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return output
    }
}
