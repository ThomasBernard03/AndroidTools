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
                let schemaLines = schemaResult.split(separator: "\n")
            }
        } catch {
            logger.error("Erreur lors de l'exécution de la commande: \(error.localizedDescription)")
        }
    }
}
