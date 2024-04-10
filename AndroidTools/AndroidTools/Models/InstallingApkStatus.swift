//
//  InstallingApkStatus.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

enum InstallingApkStatus {
    case notStarted
    case success
    case loading(fileName : String)
    case error(message : String)
}
