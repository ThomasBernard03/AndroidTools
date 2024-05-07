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
    @State private var dropTargetted: Bool = false
    
    var body: some View {
        
        let items = (viewModel.fileExplorerResult?.childrens ?? []).map { item in
            IdentifiableFileExplorerItem(item: item)
        }
        
        var currentItem: FileExplorerItem? {
            return items.first { $0.id == selection }?.item
        }
        
        ZStack(alignment:.bottom) {
            if let safeFileExplorerResult = viewModel.fileExplorerResult {
                TableView(selection: $selection, items: items, fileExplorerResult: safeFileExplorerResult) { path in
                    selection = nil
                    viewModel.getFiles(deviceId: deviceId, path: path)
                }
            }
            
            if viewModel.loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .offset(y:8)
            }
        }
        .confirmationDialog("Delete this item ?", isPresented: $viewModel.showDeleteItemAlert) {
          Button("Delete", role: .destructive) {
              let path = "\(viewModel.fileExplorerResult!.fullPath)/\(currentItem!.name)"
              selection = nil
              viewModel.deleteItem(deviceId: deviceId, path: path)
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
        .fileImporter(isPresented: $viewModel.showImportFileDialog, allowedContentTypes: [UTType.item]) { result in
            switch result {
            case .success(let file):
                viewModel.importFile(deviceId: deviceId,filePath: file.absoluteString.removingPercentEncoding ?? file.absoluteString)
            case .failure(let error):
                print(error.localizedDescription)
            }
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
                .disabled(viewModel.fileExplorerResult?.name == "")
            }
            
            ToolbarItemGroup {
                
                Button { viewModel.showImportFileDialog.toggle() } label: {
                    Label("Upload file", systemImage: "square.and.arrow.up")
                }
                Button { viewModel.showCreateFolderAlert.toggle() } label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                }
                
                Button { viewModel.showDeleteItemAlert.toggle() } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selection == nil)                
                
                Button {viewModel.getFiles(deviceId: deviceId, path: viewModel.fileExplorerResult!.fullPath)} label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.fileExplorerResult == nil)
            
            }
        }
        .disabled(viewModel.loading)
        .navigationTitle(viewModel.fileExplorerResult?.name ?? "")
    }

}

#Preview {
    FilesView(deviceId: "4dfda047")
}
