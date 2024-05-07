//
//  FileItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation


struct FileItem: FileExplorerItem {
    let name: String
    let lastModificationDate : Date
    let size : Int
}
