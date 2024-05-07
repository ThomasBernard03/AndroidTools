//
//  TableView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 07/05/2024.
//

import SwiftUI

struct TableView: View {
    @Binding var selection: IdentifiableFileExplorerItem.ID?
    let items: [IdentifiableFileExplorerItem]
    let fileExplorerResult : FileExplorerResultModel
    let onFetchFiles: (String) -> Void
    
    private var currentItem: FileExplorerItem? {
        return items.first { $0.id == selection }?.item
    }
    
    private var itemDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        Table(of: IdentifiableFileExplorerItem.self, selection: $selection) {
            TableColumn("Name") { wrapper in
                if let fileItem = wrapper.item as? FileItem {
                    FileRow(name: fileItem.name)
                } else {
                    Text(wrapper.item.name)
                }
            }
            
            TableColumn("Last Modified") { wrapper in
                if let fileItem = wrapper.item as? FileItem {
                    Text("\(fileItem.lastModificationDate, formatter: itemDateFormatter)")
                } else {
                    EmptyView()
                }
            }
            .width(140)
            
            TableColumn("Size") { wrapper in
                if let fileItem = wrapper.item as? FileItem {
                    Text(fileItem.size.toSize())
                } else {
                    EmptyView()
                }
            }
            .width(80)
        } rows: {
            ForEach(items, id: \.id) { wrapper in
                TableRow(wrapper)
                    .contextMenu {
                        Button("Rename") {
                            // TODO: open editor in inspector
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            // TODO: handle delete
                        }
                    }
            }
        }
        .contextMenu(forSelectionType: String.self, menu: { _ in }) { selection in
            if let currentFolder = currentItem as? FolderItem {
                if fileExplorerResult.fullPath.isEmpty {
                    onFetchFiles(currentFolder.name)
                }
                else {
                    let path = "\(fileExplorerResult.fullPath)/\(currentFolder.name)"
                    onFetchFiles(path)
                }
            }
        }
    }
}
