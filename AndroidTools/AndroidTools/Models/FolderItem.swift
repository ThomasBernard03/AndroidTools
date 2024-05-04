//
//  FolderItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 13/04/2024.
//

import Foundation

class FolderItem : FileExplorerItem {
    let id: UUID
    let parent: FolderItem?
    let name: String
    let path: String
    
    var fullPath: String {
        let adjustedPath = path.hasSuffix("/") ? path : path + "/"
        return adjustedPath + name
    }
    
    var childrens : [any FileExplorerItem]
    
    init(parent : FolderItem?, name: String, path: String, childrens: [any FileExplorerItem]) {
        self.id = UUID() 
        self.parent = parent
        self.name = name
        self.path = path
        self.childrens = childrens
    }
}

struct IdentifiableFileExplorerItem: Identifiable {
    let id: UUID
    let item: any FileExplorerItem

    init(item: any FileExplorerItem) {
        self.id = UUID()
        self.item = item
    }
}
