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
    
    func toFileItem(parent: FolderItem) -> [any FileExplorerItem] {
        // Découpe la chaîne de caractères en lignes
        let lines = self.split(separator: "\n")
        // Crée des tableaux vides pour les dossiers et fichiers
        var items: [any FileExplorerItem] = []

        // Parcourt chaque ligne
        for line in lines {
            let components = line.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true)

            if components.count >= 8 {
                let permissions = components[0]
                let size = Int(components[4]) ?? 0
                let date = components[5]
                let time = components[6]
                let name = components[7...]
                let filename = name.joined(separator: " ")

                if permissions.first == "d" {
                    items.append(FolderItem(parent: parent, name: filename, path: parent.fullPath, childrens: []))
                } else {
                    items.append(FileItem(parent: parent, name: filename, path: parent.fullPath, size: size))
                }
            }
        }
        
        return items
    }

}
