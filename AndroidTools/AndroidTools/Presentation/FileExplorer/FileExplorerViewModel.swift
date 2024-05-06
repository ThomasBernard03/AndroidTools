//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@Observable
final class FilesViewModel: ObservableObject {
    
    var loading : Bool = false
    
    var currentFolder: FolderItem? = nil

    var exportedDocument : UniversalFileDocument? = nil
    
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
    
    func prepareExport(deviceId : String, path: String) {
        let path = adbHelper.saveFileInTemporaryDirectory(deviceId: deviceId, filePath: path)
        if let loadedDocument = loadDocument(from: path) {
            exportedDocument = loadedDocument
        }
     }
    
    private func loadDocument(from path: String) -> UniversalFileDocument? {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let contentType = UTType(filenameExtension: url.pathExtension) ?? .item
            return UniversalFileDocument(data: data, contentType: contentType, fileName: url.lastPathComponent)
        } catch {
            print("Erreur lors du chargement du fichier : \(error)")
            return nil
        }
    }
}
