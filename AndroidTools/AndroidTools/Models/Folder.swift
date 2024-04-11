//
//  Folder.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation

struct Folder {
    var name : String
    var files : [File] = []
    var folders : [Folder] = []
}
