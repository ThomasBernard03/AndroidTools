//
//  FileExplorerResult.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

struct FileExplorerResultModel {
    let path : String
    let name : String
    
    let childrens : [any FileExplorerItem]
    
    var fullPath : String {
        var fullPath = ""
        
        if !path.isEmpty {
            fullPath = "\(path)/\(name)"
        }
        else {
            fullPath = name
        }
        
        return fullPath
    }
}
