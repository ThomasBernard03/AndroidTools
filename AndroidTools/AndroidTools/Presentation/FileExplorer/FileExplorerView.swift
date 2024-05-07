//
//  FilesView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers.UTType

struct IdentifiableFileExplorerItem: Identifiable {
    let id: String
    let item: FileExplorerItem

    init(item: FileExplorerItem) {
        self.id = item.name
        self.item = item
    }
}


struct FilesView: View {
    
    let deviceId : String
    
    @State private var viewModel = FilesViewModel()
    @State private var selection: IdentifiableFileExplorerItem.ID? = nil
    
    var body: some View {
        
        let items = (viewModel.fileExplorerResult?.childrens ?? []).map { item in
            IdentifiableFileExplorerItem(item: item)
        }
        
        var currentItem: FileExplorerItem? {
            return items.first { $0.id == selection }?.item
        }
        
        ZStack {
            if let safeFileExplorerResult = viewModel.fileExplorerResult {
                TableView(selection: $selection, items: items, fileExplorerResult: safeFileExplorerResult) { path in
                    viewModel.getFiles(deviceId: deviceId, path: path)
                }
            }
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
            Text("The folder will be created at : \n \(viewModel.fileExplorerResult?.fullPath ?? "/")")
        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId)
        }
        .onChange(of: deviceId) { _, newValue in
            viewModel.getFiles(deviceId: newValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { viewModel.getFiles(deviceId: deviceId, path: viewModel.fileExplorerResult?.path ?? "/") } label: {
                    Label("Go back", systemImage: "chevron.left")
                }
                .disabled(viewModel.loading || viewModel.fileExplorerResult?.name == "")
            }
            
            ToolbarItemGroup {
                Button { viewModel.showCreateFolderAlert.toggle() } label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .navigationTitle(viewModel.fileExplorerResult?.name ?? "")
    }

}

#Preview {
    FilesView(deviceId: "4dfda047")
}
