//
//  AdbError.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation

enum AdbError : Error {
    case notFound(path : String)
}
