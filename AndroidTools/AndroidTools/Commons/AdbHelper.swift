//
//  AdbHelper.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

class AdbHelper {
    
    var adbPath: String {
         UserDefaults.standard.string(forKey: "adbPath") ?? "/usr/local/bin/adb"
     }
    
    func getDevices() -> [DeviceListModel] {
        let command = "devices -l | awk 'NR>1 {print $1}'"
        let devicesResult = runAdbCommand(command)
        return devicesResult
            .components(separatedBy: .newlines)
            .filter({ (id) -> Bool in
                !id.isEmpty
            })
            .map { (id) -> DeviceListModel in
                DeviceListModel(id: id, name: getDeviceName(deviceId: id))
            }
    }

    
   private func getDeviceName(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell getprop ro.product.model"
        let deviceName = runAdbCommand(command)
        return deviceName
    }
    
    func saveFileInTemporaryDirectory(deviceId: String, filePath: String) -> String {
        let fileManager = FileManager.default
        let tempDirectory = NSTemporaryDirectory()
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let tempUrl = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)

        // Construire la commande ADB pour tirer le fichier de l'appareil
        let pullCommand = "-s \(deviceId) pull '/storage/emulated/0/\(filePath)' '\(tempUrl.path)'"
        
        // Exécuter la commande ADB
        let result = runAdbCommand(pullCommand)
        print("File saved in temp : \(tempUrl.path)")
        return tempUrl.path
    }
    
    func runAdbCommand(_ command: String) -> String {
        print("Running command:\nadb \(command)")
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "\(adbPath) \(command)"]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("Result:\n\(output)")
        return output
    }
    
    func runAdbCommand(_ command: String, outputHandler: @escaping (String) -> Void) {
        print("Running command:\n adb \(command)")
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "\(adbPath) \(command)"]
        task.launchPath = "/bin/sh"

        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8) {
                outputHandler(output)
            }
        }

        task.launch()
        task.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
    }
}
