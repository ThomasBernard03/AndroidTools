//
//  FileItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation


struct FileItem: FileExplorerItem {
    var parent: FileExplorerItem?
    
    let name: String
    let path : String
    var fullPath: String {
        return path + name
    }
    
    let size : Int
}
