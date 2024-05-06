//
//  InstallApplicationError.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

enum InstallApplicationError : Error {
    case unknownError(String)
    case versionDowngradeError
}
