//
//  ToastStyle.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 26/04/2024.
//

import Foundation
import SwiftUI

enum ToastStyle {
    case error
    case warning
    case success
    case info
    case loading
    
}

extension ToastStyle {
  var themeColor: Color {
    switch self {
    case .error: return Color.red
    case .warning: return Color.orange
    case .info: return Color.blue
    case .success: return Color.green
    case .loading: return Color.blue
    }
  }
  
  var iconFileName: String {
    switch self {
    case .info: return "info.circle.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .success: return "checkmark.circle.fill"
    case .error: return "xmark.circle.fill"
    case.loading: return "hourglass"
    }
  }
}
