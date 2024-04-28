//
//  FileDocument.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportableFile: FileDocument {
    static var readableContentTypes: [UTType] { [.data] } // Vous pouvez spécifier d'autres types selon vos besoins

    let fileURL: URL
    var fileTitle: String {
        fileURL.lastPathComponent
    }

    // Initialisation à partir du ReadConfiguration
    init(configuration: ReadConfiguration) throws {
        // Extrait le FileWrapper du ReadConfiguration
        guard let file = configuration.file.regularFileContents,
              let url = URL(dataRepresentation: file, relativeTo: .none) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.fileURL = url
    }

    // Initialisation simple avec une URL
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // Implémentation de la méthode de lecture requise par le protocole
    static func read(from url: URL) throws -> ExportableFile {
        // Vous pourriez ici charger des données du fichier si nécessaire
        return ExportableFile(fileURL: url)
    }

    // Fonction pour préparer un FileWrapper pour l'écriture
    func fileWrapper(configuration: FileDocumentWriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: fileURL, options: .immediate)
    }
}
