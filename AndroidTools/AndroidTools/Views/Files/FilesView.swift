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
    @State private var searchQuery : String = ""
    @State private var showImportFileDialog : Bool = false
    
    var body: some View {
        
        List(viewModel.currentFolder?.childrens ?? [], id: \.fullPath, selection: $viewModel.currentPath) { item in
            HStack {
                if let fileItem = item as? FileItem {
                    FileRow(name: fileItem.name)
                } else if let folderItem = item as? FolderItem {
                    Label(folderItem.name, systemImage: "folder")
                }
            }
        }
        .contextMenu(forSelectionType: String.self, menu: { _ in }) {_ in
            viewModel.itemDoubleClicked(deviceId: deviceId)
        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId, path:nil)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { viewModel.goBack(deviceId:deviceId) } label: {
                    Label("Go back", systemImage: "chevron.left")
                }
                .disabled(viewModel.currentFolder?.parent == nil)
            }
            ToolbarItemGroup {
                Button { showImportFileDialog.toggle() } label: {
                    Label("Upload file", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.loading)
                
                Button { } label: {
                    Label("Download file", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.currentPath == nil)
                
                Button { } label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                }
                
                Button {
                    viewModel.deleteFileExplorerItem(deviceId: deviceId, fullPath: viewModel.currentPath!)
                } label: {
                    Label("Delete", systemImage: "xmark.bin")
                }
                .disabled(viewModel.currentPath == nil || viewModel.loading)
                
                Spacer()
            }
            
            
            ToolbarItemGroup {
                Button {viewModel.refreshList(deviceId: deviceId)} label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                
                TextField("Search a file", text: $searchQuery)
                         .textFieldStyle(RoundedBorderTextFieldStyle())
                         .frame(minWidth: 200)
            }
        }
        .navigationTitle(viewModel.currentFolder?.name ?? "")
        .fileImporter(isPresented: $showImportFileDialog, allowedContentTypes: [UTType.png]) { result in
            switch result {
            case .success(let file):
                viewModel.importFile(
                    deviceId: deviceId,
                    filePath: file.absoluteString)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
