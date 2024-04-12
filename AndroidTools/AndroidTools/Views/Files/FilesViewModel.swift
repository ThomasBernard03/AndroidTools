//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation

import Foundation

final class FilesViewModel: ObservableObject {
    @Published var root: [FileItem] = []

    func getFiles(deviceId: String, path: String = "/") {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AdbHelper().getFiles(deviceId: deviceId, path: path)
            
            DispatchQueue.main.async {
                self.updateItems(at: path, with: result)
            }
        }
    }

    private func updateItems(at path: String, with result: [FileItem]) {
        if path.isEmpty || path == "/" {
            root = result
        } else {
            // Mettre à jour l'arbre à l'emplacement spécifié
            updateDirectory(&root, path: path, result: result)
        }
    }

    private func updateDirectory(_ items: inout [FileItem], path: String, result: [FileItem]) -> Bool {
        if let index = items.firstIndex(where: { $0.fullPath == path }) {
            var item = items[index]
            item.childrens = result
            items[index] = item
            return true
        } else {
            for index in 0..<items.count {
                if var children = items[index].childrens {
                    if updateDirectory(&children, path: path, result: result) {
                        items[index].childrens = children
                        return true
                    }
                }
            }
        }
        return false
    }
}
