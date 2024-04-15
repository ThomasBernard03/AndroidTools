//
//  FilesView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers.UTType

struct FilesView: View {
    
    let deviceId : String
    
    @ObservedObject private var viewModel = FilesViewModel()
    @State private var selectedPath : String? = nil
    @State private var searchQuery : String = ""
    @State private var showImportFileDialog : Bool = false
    
    var body: some View {
        
        
        List(viewModel.root, id: \.fullPath, selection: $selectedPath) { item in
            HStack {
                if let fileItem = item as? FileItem {
                    FileRow(name: fileItem.name)
                } else if let folderItem = item as? FolderItem {
                    Label(folderItem.name, systemImage: "folder")
                }
            }
        }
        .contextMenu(forSelectionType: String.self, menu: { _ in }) {_ in 
            // double tap action
            print("Double tapped")
        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId)
        }
        .toolbar {
            ToolbarItemGroup {
                Button { showImportFileDialog.toggle() } label: {
                    Label("Upload file", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.loading)
                
                Button { } label: {
                    Label("Download file", systemImage: "square.and.arrow.down")
                }
                .disabled(selectedPath == nil)
                
                Button { } label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                }
                
                Button {
                    viewModel.deleteFileExplorerItem(deviceId: deviceId, fullPath: selectedPath!)
                } label: {
                    Label("Delete", systemImage: "xmark.bin")
                }
                .disabled(selectedPath == nil || viewModel.loading)
                
                Spacer()
            }
            
            
            ToolbarItemGroup {
                Button {viewModel.getFiles(deviceId: deviceId)} label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                
                TextField("Search a file", text: $searchQuery)
                         .textFieldStyle(RoundedBorderTextFieldStyle())
                         .frame(minWidth: 200)
            }
        }
        .fileImporter(isPresented: $showImportFileDialog, allowedContentTypes: [UTType.png]) { result in
            switch result {
            case .success(let file):
                print(file.absoluteString)
                viewModel.importFile(deviceId: deviceId, filePath: file.absoluteString, targetPath: selectedPath ?? "")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
