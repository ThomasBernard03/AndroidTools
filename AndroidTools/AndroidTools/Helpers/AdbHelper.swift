//
//  AdbHelper.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

class AdbHelper {
    
    let adb = Bundle.main.url(forResource: "adb", withExtension: nil)
    
    init() {
        _ = runAdbCommand("root")
    }
    
    func getDevices() -> [Device] {
        let command = "devices -l | awk 'NR>1 {print $1}'"
        let devicesResult = runAdbCommand(command)
        return devicesResult
            .components(separatedBy: .newlines)
            .filter({ (id) -> Bool in
                !id.isEmpty
            })
            .map { (id) -> Device in
                Device(id: id, name: getDeviceName(deviceId: id))
            }
    }
    
    func getDeviceInformation(deviceId: String) -> DeviceDetail {
        
        let batteryInfoCommand = "shell dumpsys battery"
        let manufacturerCommand = "shell getprop ro.product.manufacturer"
        let modelCommand = "shell getprop ro.product.model"
        let serialNumberCommand = "get-serialno"
        let androidVersionCommand = "shell getprop ro.build.version.release"
        
        let batteryInfo = runAdbCommand("-s \(deviceId) \(batteryInfoCommand)")
        let manufacturer = runAdbCommand("-s \(deviceId) \(manufacturerCommand)")
        let model = runAdbCommand("-s \(deviceId) \(modelCommand)")
        let serialNumber = runAdbCommand("-s \(deviceId) \(serialNumberCommand)")
        let androidVersion = runAdbCommand("-s \(deviceId) \(androidVersionCommand)")
        
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

    
   private func getDeviceName(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell getprop ro.product.model"
        let deviceName = runAdbCommand(command)
        return deviceName
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
    
    func installApk(deviceId : String, path : String) -> String {
        let command = "-s \(deviceId) install \(path)"
        return runAdbCommand(command)
    }
    
    private func runAdbCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "\(adb!.path) \(command)"]
        task.launchPath = "/bin/sh"
        task.launch()

        //task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return output
    }


    
}
