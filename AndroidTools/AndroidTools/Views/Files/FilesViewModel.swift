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
    @Published var currentFolder: FolderItem? = nil
    
    @Published var loading : Bool = false
    
    @Published var exportedDocument : FileDocument? = nil
    
    @Published var currentPath : String? = nil
    
    private let adbHelper = AdbHelper()
    
    
    func itemDoubleClicked(deviceId : String){
        let selectedItem = currentFolder?.childrens.first { file in file.fullPath == currentPath }
        
        if let folderItem = selectedItem as? FolderItem {
            currentFolder = folderItem
            getFiles(deviceId: deviceId, parent: folderItem)
        }
    }

    func getFiles(deviceId: String, path : String?) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            // It's folder so get childrens
            let result = self.adbHelper.getFiles(deviceId: deviceId, path: path ?? "/")

            DispatchQueue.main.async {
                self.currentFolder = result
            }
        }
    }
    
    func getFiles(deviceId: String, parent : FolderItem) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            // It's folder so get childrens
            let result = self.adbHelper.getFiles(deviceId: deviceId, parent: parent)

            DispatchQueue.main.async {
                self.currentFolder = result
            }
        }
    }
    
    func goBack(deviceId : String){
        if let parent = currentFolder?.parent {
            currentFolder = parent
        }
    }
    
    func refreshList(deviceId : String){
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            if let parent = currentFolder {
                let result = self.adbHelper.getFiles(deviceId: deviceId, parent: parent)

                DispatchQueue.main.async {
                    self.currentFolder = result
                }
            }
        }
    }
    
    func deleteFileExplorerItem(deviceId : String, fullPath : String){
        if loading { return }
        loading = true
    
        DispatchQueue.global(qos: .userInitiated).async {
            let fileDeleted = self.adbHelper.deleteFileExplorerItem(deviceId: deviceId, fullPath: fullPath)
            self.refreshList(deviceId: deviceId)
            
            DispatchQueue.main.async {
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
            
            self.refreshList(deviceId: deviceId)
            
            DispatchQueue.main.async {
                self.loading = false
            }
        }
    }
}
