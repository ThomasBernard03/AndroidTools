//
//  FileItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation


class FileItem: FileExplorerItem {
    let id : UUID
    let parent: FolderItem?
    
    let name: String
    let path : String
    
    var fullPath: String {
        let adjustedPath = path.hasSuffix("/") ? path : path + "/"
        return adjustedPath + name
    }
    
    let size : Int
    
    init(parent : FolderItem?, name: String, path: String, size: Int) {
        self.id = UUID()
        self.parent = parent
        self.name = name
        self.path = path
        self.size = size
    }
}
