//
//  IntExtensions.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation


import Foundation

extension Int {
    func toBatteryIcon() -> String {
        let iconName: String
        
        switch self {
        case 0..<20:
            iconName = "battery.0percent"
        case 20..<40:
            iconName = "battery.25percent"
        case 40..<60:
            iconName = "battery.50percent"
        case 60..<80:
            iconName = "battery.75percent"
        case 80...100:
            iconName = "battery.100percent"
        default:
            iconName = "battery.unknown"
        }
        
        return iconName
    }
    
    // Return size in bytes, KB, MB or GB
    func toSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes ,.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }

}

