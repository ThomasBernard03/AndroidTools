//
//  AdbHelper.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

class AdbHelper {
    
    let adbPath = "/usr/local/bin/adb"
    
    init() {
        // _ = runAdbCommand("root")
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
    
    func createFolder(deviceId : String, path : String, name : String) {
        let directoryPath = "/storage/emulated/0\(path)/\(name)"
        let createDirCommand = "-s \(deviceId) shell mkdir -p \"\(directoryPath)\""
        let result = runAdbCommand(createDirCommand)
    }

    
    func getFiles(deviceId : String, path : String) -> FolderItem {
        let finalPath = "/storage/emulated/0" + path
        let result = runAdbCommand("-s \(deviceId) shell ls \(finalPath) -l")
        
        
        
        let parent = FolderItem(
            parent: nil,
            name: path.isEmpty ? "/" : path.substringAfterLast("/"),
            path: path.isEmpty ? "/" : "/" + path.substringBeforeLast("/"),
            childrens: [])
        
        let childrens = result.toFileItem(parent:parent)
        
        parent.childrens = childrens
        
        return parent
    }
    
    func getFiles(deviceId : String, parent : FolderItem) -> FolderItem {
        let finalPath = "/storage/emulated/0" + parent.fullPath
        let result = runAdbCommand("-s \(deviceId) shell ls \(finalPath) -l")
        
        
        let childrens = result.toFileItem(parent:parent)
        
        parent.childrens = childrens
        
        return parent
    }
    
    func deleteFileExplorerItem(deviceId: String, fullPath: String) -> String {
        let deleteCommand = "shell 'rm -r \"/storage/emulated/0\(fullPath)\"'"
        let result = runAdbCommand("-s \(deviceId) \(deleteCommand)")
        return result
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
        let pullCommand = "-s \(deviceId) pull '/storage/emulated/0\(filePath)' '\(tempUrl.path)'"
        
        // Exécuter la commande ADB
        let result = runAdbCommand(pullCommand)
        print("File saved in temp : \(tempUrl.path)")
        return tempUrl.path
    }

    
    func importFile(deviceId: String, filePath: String, targetPath: String) -> String {
        let cleanedFilePath = filePath.replacingOccurrences(of: "file://", with: "")
        let targetDevicePath = "/storage/emulated/0\(targetPath)"
        let pushCommand = "-s \(deviceId) push \"\(cleanedFilePath)\" \"\(targetDevicePath)\""
        
        let result = runAdbCommand(pushCommand)
        return result
    }
    
    func runAdbCommand(_ command: String) -> String {
        print("Running command: adb \(command)")
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "\(adbPath) \(command)"]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("Result: \(output)")
        return output
    }
}
