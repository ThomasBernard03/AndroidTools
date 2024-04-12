//
//  FileItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation


struct FileItem: Hashable, Identifiable {
    var id: Self { self }
    var name: String
    var path : String
    var childrens: [FileItem]? = nil
    var size : Int
    
    var fullPath: String {
        path + name
    }
}
