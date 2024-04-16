//
//  FolderItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 13/04/2024.
//

import Foundation

class FolderItem : FileExplorerItem {    
    let parent: FolderItem?
    let name: String
    let path: String
    
    var fullPath: String {
        return path + name
    }
    
    var childrens : [any FileExplorerItem]
    
    init(parent : FolderItem?, name: String, path: String, childrens: [any FileExplorerItem]) {
        self.parent = parent
        self.name = name
        self.path = path
        self.childrens = childrens
    }
}
