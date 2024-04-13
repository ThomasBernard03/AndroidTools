//
//  FolderItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 13/04/2024.
//

import Foundation

struct FolderItem : FileExplorerItem {
    let name: String
    let path: String
    var fullPath: String {
        return path + name + "/"
    }
    
    var childrens : [any FileExplorerItem]
}
