//
//  FileDocument.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct UniversalFileDocument: FileDocument {
    var data: Data
    var contentType: UTType
    var fileName : String

    static var readableContentTypes: [UTType] { [.item] } // Accepte n'importe quel type de fichier

    init(data: Data, contentType: UTType = .plainText, fileName : String) {
        self.data = data
        self.contentType = contentType
        self.fileName = fileName
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
        self.contentType = configuration.contentType
        self.fileName = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = FileWrapper(regularFileWithContents: self.data)
        wrapper.preferredFilename = "ExportedFile.\(contentType.preferredFilenameExtension ?? "dat")"
        return wrapper
    }
}
