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
    
   private func getDeviceName(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell getprop ro.product.model"
        let deviceName = runAdbCommand(command)
        return deviceName
    }
    
    func installApk(path : String) -> String {
        let command = "install \(path)"
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
