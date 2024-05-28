//
//  DatabaseExplorerTableViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/05/2024.
//

import Foundation
import os

class DatabaseExplorerTableViewModel : ObservableObject {
    
    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    @Published var columns : [DatabaseColumn] = []
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DatabaseExplorerTableViewModel.self)
    )
    
    func getTable(deviceId : String, packageName : String, table : String){
        do {
            let databasesFiles = try adbRepository.runAdbCommand("shell 'run-as \(packageName) sh -c \"cd databases; ls\"'")
            let files = databasesFiles.split(separator: "\n").map { String($0) }
            
            if let databaseFile = files.first {
                // Get table schema
                let schemaResult = try adbRepository.runAdbCommand("shell 'run-as \(packageName) sh -c \"cd databases; sqlite3 \(databaseFile) \\\".schema \(table)\\\"\"'")
                
                // Parse the schema result to get column names
                let parsedColumns = parseColumnNames(from: schemaResult)
                
                let rowsResult = try adbRepository.runAdbCommand("shell 'run-as \(packageName) sh -c \"cd databases; sqlite3 \(databaseFile) \\\"SELECT * FROM \(table)\\\"\"'").split(separator: "\n").map { String($0).split(separator: "|").map { String($0) } }
                
                self.columns = parsedColumns.enumerated().map { index, column in
                    let values = rowsResult.map { row in
                        row[index]
                    }
                    return DatabaseColumn(name: column, values: values)
                }

            }
        } catch {
            logger.error("Erreur lors de l'exécution de la commande: \(error.localizedDescription)")
        }
    }
    

    func parseColumnNames(from createTableSQL: String) -> [String] {
        // Extraire uniquement la portion de la chaîne de création de table qui contient les colonnes
        guard let tableDefinition = createTableSQL.components(separatedBy: "(").dropFirst().first?.components(separatedBy: ")").first else {
            return []
        }
        
        // Expression régulière pour extraire les colonnes dans la définition des colonnes
        let pattern = "\\`(\\w+)\\`\\s+\\w+"
        
        // Tableau pour stocker les noms des colonnes
        var columnNames: [String] = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = tableDefinition as NSString
            let matches = regex.matches(in: tableDefinition, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    let columnNameRange = match.range(at: 1)
                    let columnName = nsString.substring(with: columnNameRange)
                    columnNames.append(columnName)
                }
            }
        } catch let error {
            print("Erreur lors de la création de l'expression régulière : \(error)")
        }
        
        return columnNames
    }

}
