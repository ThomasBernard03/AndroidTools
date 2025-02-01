////
////  FileLogger.swift
////  AndroidTools
////
////  Created by Thomas Bernard on 29/01/2025.
////
//
//
//import Foundation
//
//class FileLogger: Logger {
//    
//    private let logFileURL: URL
//    
//    init(filename: String = "app.log") {
//        let fileManager = FileManager.default
//        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//        
//        // Create the directory if it doesn’t exist
//        try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
//        
//        logFileURL = appSupportDir.appendingPathComponent(filename)
//    }
//    
//    func log(_ message: String) {
//        let timestamp = Date().formatted(date: .numeric, time: .standard)
//        let logMessage = "[\(timestamp)] \(message)\n"
//        
//        if let data = logMessage.data(using: .utf8) {
//            if FileManager.default.fileExists(atPath: logFileURL.path) {
//                // Append to the file
//                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
//                    fileHandle.seekToEndOfFile()
//                    fileHandle.write(data)
//                    fileHandle.closeFile()
//                }
//            } else {
//                // Create new file
//                try? data.write(to: logFileURL, options: .atomicWrite)
//            }
//        }
//    }
//    
//    func getLogFilePath() -> URL {
//        return logFileURL
//    }
//}
