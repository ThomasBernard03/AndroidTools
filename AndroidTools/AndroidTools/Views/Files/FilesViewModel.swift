//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation
import SwiftUI

@Observable
final class FilesViewModel: ObservableObject {
    var currentFolder: FolderItem? = nil
    
    var loading : Bool = false
    
    var exportedDocument : ExportableFile? = nil
    
    var currentPath : String? = nil
    
    var showCreateFolderAlert = false
    var createFolderAlertName = ""
    
    var showExporter = false
    
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
                self.currentPath = nil
                self.currentFolder = result
            }
        }
    }
    
    func goBack(deviceId : String){
        if let parent = currentFolder?.parent {
            currentPath = nil
            currentFolder = parent
        }
    }
    
    func downloadFile(deviceId : String){
        adbHelper.saveFile(deviceId: deviceId, filePath: currentPath!)
        showExporter.toggle()
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
                self.currentPath = nil
            }
        }
    }
    
    
    func importFile(deviceId : String, filePath : String) {
        if loading { return }
        loading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileImported = self.adbHelper.importFile(
                deviceId: deviceId,
                filePath: filePath,
                targetPath: self.currentFolder?.fullPath ?? "/")
            
            self.refreshList(deviceId: deviceId)
            
            DispatchQueue.main.async {
                self.loading = false
            }
        }
    }
    
    func createFolder(deviceId : String){
        if loading { return }
        loading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.adbHelper.createFolder(deviceId: deviceId, path: self.currentFolder?.fullPath ?? "/", name: self.createFolderAlertName)
            
            self.refreshList(deviceId: deviceId)
            
            DispatchQueue.main.async {
                self.currentPath = self.currentFolder?.fullPath ?? "/" + self.createFolderAlertName
                self.loading = false
            }
        }
    }
    
    func prepareExport(fileURL: String) {
        if let url = URL(string: fileURL) {
            // self.exportedDocument = ExportableFile(configuration: url)
            print(self.exportedDocument?.fileTitle)
        } else {
            print("Invalid URL string: \(fileURL)")
        }
     }
}
