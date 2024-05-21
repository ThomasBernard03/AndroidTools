//
//  LogLevelExtensions.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 08/05/2024.
//

import Foundation
import SwiftUI

extension LogLevel {
    func iconBackgroundColor() -> Color {
        switch(self){
        case .verbose:
            Color("LogcatVerboseIconBackground")
        case .debug:
            Color("LogcatDebugIconBackground")
        case .info:
            Color("LogcatInfoIconBackground")
        case .warning:
            Color("LogcatWarningIconBackground")
        case .error:
            Color("LogcatErrorIconBackground")
        }
    }
    
    func iconForegroundColor() -> Color {
        switch(self){
        case .verbose:
            Color("LogcatVerboseIconForeground")
        case .debug:
            Color("LogcatDebugIconForeground")
        case .info:
            Color("LogcatInfoIconForeground")
        case .warning:
            Color("LogcatWarningIconForeground")
        case .error:
            Color("LogcatErrorIconForeground")
        }
    }
    
    func textColor() -> Color {
        switch(self){
        case .verbose:
            Color("LogcatVerboseText")
        case .debug:
            Color("LogcatDebugText")
        case .info:
            Color("LogcatInfoText")
        case .warning:
            Color("LogcatWarningText")
        case .error:
            Color("LogcatErrorText")
        }
    }
}
