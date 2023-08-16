//
//  AdbHelper.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 11/03/21.
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
    
    func getDeviceName(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell getprop ro.product.model"
        let deviceName = runAdbCommand(command)
        return deviceName
    }
    
    func getFiles(directory : String = "/", completion : @escaping ([File]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let command = "shell ls \(directory)"
            let output = self.runAdbCommand(command)
            let names = output.components(separatedBy: .newlines).filter { !$0.isEmpty }

            var files: [File] = []

            for name in names {
                let fullPath = directory.hasSuffix("/") ? directory + name : directory + "/" + name
                
                let detailsCommand = "shell ls -ld \(name)"
                let details = self.runAdbCommand(detailsCommand)
                
                let isFile = !details.hasPrefix("d")
                
                let sizeCommand = isFile ? "shell stat -c %s \(name)" : "echo 0"
                let sizeStr = self.runAdbCommand(sizeCommand)
                let size = Int(sizeStr) ?? 0
                
                let dateCommand = "shell stat -c %Y \(name)"
                let dateTimestampStr = self.runAdbCommand(dateCommand)
                let timestamp = TimeInterval(dateTimestampStr) ?? 0
                let date = Date(timeIntervalSince1970: timestamp)
                
                files.append(File(name: name, modificationDate: date, isFile: isFile, size: size, path: fullPath))
            }
            
            DispatchQueue.main.async {
                completion(files)
            }
        }
    }





    
    private func runAdbCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", adb!.path + " " + command]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
        return output
    }
    
}

