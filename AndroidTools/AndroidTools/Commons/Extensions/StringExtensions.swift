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
    
    func toFileItem() -> [FileItem] {
        // Découpe la chaîne de caractères en lignes
        let lines = self.split(separator: "\n")
        // Crée des tableaux vides pour les dossiers et fichiers
        var childrens: [FileItem] = []

        // Parcourt chaque ligne
        for line in lines {
            let components = line.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true)
            if components.count >= 8, let name = components.last, let sizeString = components[4].split(separator: " ").first, let size = Int(sizeString) {
                let dateString = "\(components[5]) \(components[6]) \(components[7])"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                let date = dateFormatter.date(from: dateString) ?? Date()
                
                if line.hasPrefix("d") {
                    // Il s'agit d'un dossier
                    childrens.append(FileItem(name: String(name), childrens: [], size: size))
                } else {
                    // Il s'agit d'un fichier
                    childrens.append(FileItem(name: String(name), childrens: nil, size: size))
                }
            }
        }
        
        return childrens
    }
}
