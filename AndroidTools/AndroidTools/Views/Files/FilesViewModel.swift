//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation

import Foundation
import SwiftUI

final class FilesViewModel: ObservableObject {
    @Published var files: [any FileExplorerItem] = []
    
    @Published var loading : Bool = false
    
    @Published var exportedDocument : FileDocument? = nil
    
    @Published var currentPath : String? = nil
    @Published var currentFolder : FolderItem? = nil
    
    private let adbHelper = AdbHelper()

    func getFiles(deviceId: String, path: String = "/") {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            let selectedFile = files.first { file in
                file.fullPath == currentPath
            }
            
            // If it's a file, get list of parent
            if selectedFile as? FileItem != nil {
                let result = self.adbHelper.getFiles(deviceId: deviceId, file: selectedFile?.parent)
                
                DispatchQueue.main.async {
                    self.files = result

                }
            }
            // It's folder so get childrens
            else {
                let result = self.adbHelper.getFiles(deviceId: deviceId, file: selectedFile)
                
                DispatchQueue.main.async {
                    self.files = result
                }
            }
        }
    }
    
    func GoBack(){
        files = (files.first?.parent as? FolderItem)?.childrens ?? files
    }

    private func updateItems(at path: String, with result: [any FileExplorerItem]) {
        if path.isEmpty || path == "/" {
            files = result
        } else {
            _ = updateDirectory(&files, path: path, result: result)
        }
    }

    private func updateDirectory(_ items: inout [any FileExplorerItem], path: String, result: [any FileExplorerItem]) -> Bool {
        for index in items.indices {
            if items[index].fullPath == path, var folderItem = items[index] as? FolderItem {
                folderItem.childrens = result
                items[index] = folderItem
                return true
            } else if var folderItem = items[index] as? FolderItem {
                if updateDirectory(&folderItem.childrens, path: path, result: result) {
                    items[index] = folderItem
                    return true
                }
            }
        }
        return false
    }
    
    func deleteFileExplorerItem(deviceId : String, fullPath : String){
        if loading { return }
        loading = true
    
        DispatchQueue.global(qos: .userInitiated).async {
            let fileDeleted = self.adbHelper.deleteFileExplorerItem(deviceId: deviceId, fullPath: fullPath)
            
            DispatchQueue.main.async {
                self.getFiles(deviceId: deviceId, path: self.currentPath ?? "/")
                self.loading = false
            }
        }
    }
    
    
    func importFile(deviceId : String, filePath : String, targetPath : String) {
        if loading { return }
        loading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileImported = self.adbHelper.importFile(
                deviceId: deviceId,
                filePath: filePath,
                targetPath: targetPath)
            
            DispatchQueue.main.async {
                self.getFiles(deviceId: deviceId, path: self.currentPath ?? "/")
                self.loading = false
            }
        }
    }
}
