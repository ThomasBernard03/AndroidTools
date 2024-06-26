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
    
    private let adbHelper = AdbHelper()
    private let listFilesUseCase = ListFilesUseCase()
    private let createFolderUseCase = CreateFolderUseCase()
    private let deleteFileItemUseCase = DeleteFileItemUseCase()
    private let importFileUseCase = ImportFileUseCase()
    
    private var temporaryFilePath : String = ""
    
    var loading : Bool = true
    var fileExplorerResult: FileExplorerResultModel? = nil
    var showCreateFolderAlert = false
    var showDeleteItemAlert = false
    var showExportFileDialog : Bool = false
    var showImportFileDialog : Bool = false
    var createFolderAlertName = ""
    var exportedDocument : UniversalFileDocument? = nil
    
    func getFiles(deviceId: String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let filesResult = listFilesUseCase.execute(deviceId: deviceId)
            DispatchQueue.main.async {
                self.loading = false
                self.fileExplorerResult = filesResult
            }
        }
    }
    
    func getFiles(deviceId: String, path : String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let filesResult = listFilesUseCase.execute(deviceId: deviceId, path: path)
            DispatchQueue.main.async {
                self.loading = false
                self.fileExplorerResult = filesResult
            }
        }
    }
    
    func createFolder(deviceId : String){
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            createFolderUseCase.execute(deviceId: deviceId, path: fileExplorerResult!.fullPath, name: createFolderAlertName)
            getFiles(deviceId: deviceId, path: fileExplorerResult!.fullPath)
            DispatchQueue.main.async {
                self.loading = false
            }
        }
    }
    
    func deleteItem(deviceId : String, path : String, name : String){
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            deleteFileItemUseCase.execute(deviceId: deviceId, path: path, name:name)
            getFiles(deviceId: deviceId, path: fileExplorerResult!.fullPath)
            DispatchQueue.main.async {
                self.loading = false
            }
        }
    }
    
    func importFile(deviceId : String, filePath : String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            importFileUseCase.execute(deviceId: deviceId, filePath: filePath, targetPath: fileExplorerResult!.fullPath)
            getFiles(deviceId: deviceId, path: fileExplorerResult!.fullPath)
            DispatchQueue.main.async {
                self.loading = false
            }
        }
    }
    
    
    func prepareExport(deviceId : String, filePath: String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            temporaryFilePath = adbHelper.saveFileInTemporaryDirectory(deviceId: deviceId, filePath: filePath)
            if let loadedDocument = loadDocument(from: temporaryFilePath) {
                DispatchQueue.main.async {
                    self.exportedDocument = loadedDocument
                    self.loading = false
                }
            }
        }
     }
    
    func fileExported(){
        do {
            try FileManager.default.removeItem(at: URL(string: temporaryFilePath)!)
            print("Temporary file \(temporaryFilePath) deleted")
            temporaryFilePath = ""
        }
        catch {
            print("Error when deleting temporary file: \(error)")
        }
    }
    
    private func loadDocument(from path: String) -> UniversalFileDocument? {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let contentType = UTType(filenameExtension: url.pathExtension) ?? .item
            return UniversalFileDocument(data: data, contentType: contentType, fileName: url.lastPathComponent)
        } catch {
            print("Error when loading file : \(error)")
            return nil
        }
    }
}
