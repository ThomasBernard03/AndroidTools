//
//  LogLineModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 08/05/2024.
//

import Foundation


struct LogEntryModel : Identifiable, Hashable {
    let id : UUID = UUID()
    
    var datetime: Date
    var processID: Int
    var threadID: Int
    var level: LogLevel
    var tag: String
    var message: String
}
