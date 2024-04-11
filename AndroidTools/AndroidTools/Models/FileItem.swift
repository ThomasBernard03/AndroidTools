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
    var childrens: [FileItem]? = nil
    var size : Int
    var description: String {
             switch childrens {
             case nil:
                 return "📄 \(name)"
             case .some(let children):
                 return children.isEmpty ? "📂 \(name)" : "📁 \(name)"
             }
         }
}
