//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation

import Foundation

final class FilesViewModel: ObservableObject {
    @Published var root: [any FileExplorerItem] = []
    @Published var deleting : Bool = false
    
    
    private let adbHelper = AdbHelper()

    func getFiles(deviceId: String, path: String = "/") {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.adbHelper.getFiles(deviceId: deviceId, path: path)
            
            DispatchQueue.main.async {
                self.updateItems(at: path, with: result)
            }
        }
    }

    private func updateItems(at path: String, with result: [any FileExplorerItem]) {
        if path.isEmpty || path == "/" {
            root = result
        } else {
            _ = updateDirectory(&root, path: path, result: result)
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
        
        if deleting {
            return
        }
        
        deleting = true
    
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.adbHelper.deleteFileExplorerItem(deviceId: deviceId, fullPath: fullPath)
            
            DispatchQueue.main.async {
                self.deleting = false
                let parentPath = self.getParentPath(fromFullPath: fullPath)
                self.getFiles(deviceId: deviceId, path: parentPath)
                
            }
        }
        
    }
    
    private func getParentPath(fromFullPath fullPath: String) -> String {
        let pathComponents = fullPath.split(separator: "/").dropLast()
        if pathComponents.isEmpty {
            return "/"
        } else {
            return "/" + pathComponents.joined(separator: "/") + "/"
        }
    }
}
