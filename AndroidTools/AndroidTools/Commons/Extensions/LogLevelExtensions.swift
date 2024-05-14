//
//  LogLevelExtensions.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 08/05/2024.
//

import Foundation
import SwiftUI

extension LogLevel {
    func color() -> Color {
        switch(self){
        case .verbose:
            Color("VerboseLogLevel")
        case .debug:
            Color("DebugLogLevel")
        case .info:
            Color("InfoLogLevel")
        case .warning:
            Color("WarningLogLevel")
        case .error:
            Color("ErrorLogLevel")
        }
    }
}
