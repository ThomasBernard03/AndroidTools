//
//  Logger.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 29/01/2025.
//


protocol Logger {
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}
