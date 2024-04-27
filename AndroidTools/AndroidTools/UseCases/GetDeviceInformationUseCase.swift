//
//  GetDeviceInformationUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation

class GetDeviceInformationUseCase {
    
    private let adbHelper = AdbHelper()
    
    func execute(deviceId : String) -> DeviceDetail {
        let batteryInfoCommand = "shell dumpsys battery"
        let manufacturerCommand = "shell getprop ro.product.manufacturer"
        let modelCommand = "shell getprop ro.product.system.marketname"
        let serialNumberCommand = "get-serialno"
        let androidVersionCommand = "shell getprop ro.build.version.release"
        
        let batteryInfo = adbHelper.runAdbCommand("-s \(deviceId) \(batteryInfoCommand)")
        let manufacturer = adbHelper.runAdbCommand("-s \(deviceId) \(manufacturerCommand)")
        let model = adbHelper.runAdbCommand("-s \(deviceId) \(modelCommand)")
        let serialNumber = adbHelper.runAdbCommand("-s \(deviceId) \(serialNumberCommand)")
        let androidVersion = adbHelper.runAdbCommand("-s \(deviceId) \(androidVersionCommand)")
        
        let infos = deserializeBatteryInfo(batteryInfo)

        return DeviceDetail(
            manufacturer: manufacturer,
            model: model,
            serialNumber: serialNumber,
            androidVersion: androidVersion,
            batteryInfo: BatteryInfo(
                charging: infos["AC powered"] as? Bool ?? false,
                percentage: infos["level"] as? Int ?? 0
            )
        )
    }
    
    
    private func deserializeBatteryInfo(_ info: String) -> [String: Any] {
        var batteryDict: [String: Any] = [:]
        let lines = info.split(separator: "\n")
        
        for line in lines {
            let components = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if components.count == 2 {
                let key = components[0]
                let value = components[1]
                
                // Essayez de convertir la valeur en Int ou Bool si possible
                if let intValue = Int(value) {
                    batteryDict[key] = intValue
                } else if let boolValue = Bool(value.lowercased()) {
                    batteryDict[key] = boolValue
                } else {
                    batteryDict[key] = value
                }
            }
        }
        
        return batteryDict
    }
}
