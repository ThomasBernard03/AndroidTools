//
//  StringExtensions.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

extension String {
    func substringAfterLast(_ delimiter: String) -> String {
        guard let range = self.range(of: delimiter, options: .backwards) else {
            return self
        }

        let indexAfterDelimiter = self.index(range.upperBound, offsetBy: 0)
        return String(self[indexAfterDelimiter...])
    }
    
    func substringBeforeLast(_ delimiter: String) -> String {
        guard let range = self.range(of: delimiter, options: .backwards) else {
            return self
        }

        return String(self[..<range.lowerBound])
    }
    
    func toFileItem(parent : FolderItem) -> [FileExplorerItem] {
        // Découpe la chaîne de caractères en lignes
        let lines = self.split(separator: "\n")
        // Crée des tableaux vides pour les dossiers et fichiers
        var items: [FileExplorerItem] = []

        // Parcourt chaque ligne
        for line in lines {
            let components = line.split(separator: " ")
            if components.count >= 8, let name = components.last {
                // If it's a folder
                if line.hasPrefix("d") {
                    items.append(FolderItem(parent: parent, name: String(name), path: parent.path, childrens: []))
                }
                // It's a file
                else {
                    let size = Int(components[4]) ?? 0
                    items.append(FileItem(parent : parent, name: String(name), path : parent.path, size: size))
                }
            }
        }
        
        return items
    }
}
