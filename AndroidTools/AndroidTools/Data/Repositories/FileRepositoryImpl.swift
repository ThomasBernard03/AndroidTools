//
//  FileRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

class FileRepositoryImpl : FileRepository {

    

    private let adbHelper = AdbHelper()
    let basePath = "/storage/emulated/0/"
    
    
    func createFolder(deviceId: String, path: String, name: String) {
        let directoryPath = "\(basePath)\(path)/\(name)"
        let createDirCommand = "-s \(deviceId) shell mkdir -p \"\(directoryPath)\""
        _ = adbHelper.runAdbCommand(createDirCommand)
    }
    
    func deleteFileItem(deviceId: String, path: String) {
        let deleteCommand = "shell 'rm -r \"\(basePath)\(path)\"'"
        _ = adbHelper.runAdbCommand("-s \(deviceId) \(deleteCommand)")
    }
    
    
    func getFiles(deviceId: String, path: String) -> FileExplorerResultModel {
        let finalPath = basePath + path
        
        let result = adbHelper.runAdbCommand("-s \(deviceId) shell ls \(finalPath) -l")
        return parseFileResult(path: path, result: result)
    }
    
    private func parseFileResult(path : String, result : String) -> FileExplorerResultModel {
        let childrens = result.toFileItem(path:path)
        let parentName = path.substringAfterLast("/")
        
        
        var path = path.substringBeforeLast(parentName)
        
        if path.last == "/" {
            path.removeLast()
        }
        
        
        
        let parent = FileExplorerResultModel(path: path, name: parentName, childrens: childrens)
        return parent
    }
}
