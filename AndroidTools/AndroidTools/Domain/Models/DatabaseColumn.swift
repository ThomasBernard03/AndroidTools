//
//  DatabaseColumn.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/05/2024.
//

import Foundation

struct DatabaseColumn : Identifiable {
    let id : UUID = UUID()
    let name : String
    let values : [String]
}
