//
//  FileList.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/04/2024.
//

import SwiftUI

struct FileList: View {
    
    let files : [any FileExplorerItem]  // Accepte des éléments de type protocol avec 'any'
    let selection : Binding<String?>
    let onTap: (String) -> Void
    let onDoubleTap: (String) -> Void
    
    var body: some View {
        ForEach(files, id: \.fullPath) { item in
            HStack {
                if let fileItem = item as? FileItem {
                    FileRow(name: fileItem.name)
                } else if let folderItem = item as? FolderItem {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(folderItem.childrens.isEmpty ? 0 : 90))
                        .animation(.easeInOut, value: folderItem.childrens.isEmpty)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onDoubleTap(folderItem.fullPath)
                        }
                    Label(folderItem.name, systemImage: "folder")
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onDoubleTap(item.fullPath)
            }
            .onTapGesture {
                onTap(item.fullPath)
            }
            if let folderItem = item as? FolderItem, !folderItem.childrens.isEmpty {
                FileList(files: folderItem.childrens, selection: selection, onTap: onTap, onDoubleTap: onDoubleTap)
                    .padding([.leading])
            }
        }
    }
}
