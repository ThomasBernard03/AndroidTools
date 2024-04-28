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
    
    @State private var viewModel = FilesViewModel()
    @State private var searchQuery : String = ""
    @State private var showImportFileDialog : Bool = false
    @State private var showExportFileDialog : Bool = false
    @State private var dropTargetted: Bool = false
    
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
        .onDrop(of: [.item], isTargeted: $dropTargetted) { providers in
            providers.first?.loadItem(forTypeIdentifier: UTType.item.identifier, options: nil) { (item, error) in
                if let item = item as? URL {
                    let fileUrl = item.startAccessingSecurityScopedResource() ? item : URL(fileURLWithPath: item.path)
                    viewModel.importFile(deviceId: deviceId, filePath: fileUrl.path)
                    item.stopAccessingSecurityScopedResource()
                }
            }
            return true
        }
        .overlay {
            if dropTargetted {
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                        Text("Drop your file here...")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                }
            }
        }
        .contextMenu(forSelectionType: String.self, menu: { _ in }) {_ in
            viewModel.itemDoubleClicked(deviceId: deviceId)
        }
        .alert("Create folder", isPresented: $viewModel.showCreateFolderAlert){
            TextField("Folder name", text: $viewModel.createFolderAlertName)
            HStack {
                Button("Create",action: {
                    viewModel.createFolder(deviceId: deviceId)
                })
                    .disabled(viewModel.createFolderAlertName.isEmpty)
                
                Button("Cancel",action: {})
            }
        } message: {
            Text("The folder will be created at : \n \(viewModel.currentFolder?.fullPath ?? "/")")
        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId, path:nil)
        }
        .onChange(of: deviceId, { oldValue, newValue in
            viewModel.getFiles(deviceId: newValue, path:nil)
        })
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
                
                Button {
                    showExportFileDialog.toggle()
                } label: {
                    Label("Download file", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.currentPath == nil || viewModel.loading)
                
                Button {viewModel.showCreateFolderAlert.toggle()} label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                }
                
                Button {
                    viewModel.deleteFileExplorerItem(deviceId: deviceId, fullPath: viewModel.currentPath!)
                } label: {
                    Label("Delete", systemImage: "trash")
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
        .fileImporter(isPresented: $showImportFileDialog, allowedContentTypes: [UTType.item]) { result in
            switch result {
            case .success(let file):
                viewModel.importFile(deviceId: deviceId,filePath: file.absoluteString)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
