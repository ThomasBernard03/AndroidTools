//
//  FileExplorerItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 13/04/2024.
//

import Foundation

protocol FileExplorerItem {
    var parent : FileExplorerItem? { get }
    var name: String { get }
    var path : String { get }
    
    var fullPath : String { get }
}
