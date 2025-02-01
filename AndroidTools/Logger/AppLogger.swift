//
//  AppLogger.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 29/01/2025.
//


import OSLog

struct AppLogger : Logger {
    
    private let logger = os.Logger.init(subsystem: "fr.thomasbernard.AndroidTools", category: "general")
    
    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
    
    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
    
    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }
    
    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
