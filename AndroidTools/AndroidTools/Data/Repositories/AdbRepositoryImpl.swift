//
//  AdbRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation
import os
import Combine

class AdbRepositoryImpl : AdbRepository {

    private var shellHelper : ShellHelper = ShellHelper()
    
    private var adbPath: String {
        var preferencePath = UserDefaults.standard.string(forKey: "adbPath")
        
        if preferencePath == nil {
            if let path = try? getDefaultPath() {
                preferencePath = path
            } else {
                preferencePath = ""
            }
        }
        
        return preferencePath!
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdbRepositoryImpl.self)
    )
    
    func runAdbCommand(_ command: String) throws -> String {
        return shellHelper.runAdbCommand("\(adbPath) \(command)")
    }
    
    func runAdbCommand(_ command: String, outputHandler: @escaping (String) -> Void) {
        return shellHelper.runAdbCommand("\(adbPath) \(command)", outputHandler: outputHandler)
    }
    
    func runAdbCommandCombine(_ command: String) -> AnyPublisher<String, Never>  {
        return shellHelper.runAdbCommandCombine("\(adbPath) \(command)")
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
    
    func getPath() throws -> String {
        return adbPath
    }
    
    private func getDefaultPath() throws -> String {
        let result = shellHelper.runAdbCommand("which adb")
        if result.contains("not found"){
            throw AdbError.notExists
        }
        else {
            return result
        }
    }
    
    func setPath(path : String?) -> String {
        
        if path == nil {
            let defaultPath = try? getDefaultPath()
            UserDefaults.standard.set(defaultPath, forKey: "adbPath")
        }
        else {
            UserDefaults.standard.set(path, forKey: "adbPath")
        }
        
        return adbPath
    }
}
