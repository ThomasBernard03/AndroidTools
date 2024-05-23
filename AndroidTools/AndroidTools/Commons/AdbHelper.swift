//
//  AdbHelper.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

class AdbHelper {
    
    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    
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
        let result = try? adbRepository.runAdbCommand(command)
        return result ?? ""
    }
    
    func runAdbCommand(_ command: String, outputHandler: @escaping (String) -> Void) {
        adbRepository.runAdbCommand(command, outputHandler: outputHandler)
    }
}
