//
//  FilesView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct FilesView: View {
    
    let deviceId : String
    
    @ObservedObject private var viewModel = FilesViewModel()
    @State private var selectedPath : String? = nil
    @State private var searchQuery : String = ""

    
    var body: some View {
        
        List(selection: $selectedPath) {
            FileList(
                files: viewModel.root,
                selection:$selectedPath
            ) { path in
                selectedPath = path
            } onDoubleTap: { path in
                if selectedPath == path {
                    selectedPath = nil
                    if let index = viewModel.root.firstIndex(where: { path == $0.fullPath}) {
                        
                        if var folder = viewModel.root[index] as? FolderItem {
                            folder.childrens.removeAll()
                            viewModel.root[index] = folder
                        }
                        
                       
                    }
                }
                else {
                    selectedPath = path
                    if path.last == "/" {
                        viewModel.getFiles(deviceId: deviceId, path: path)
                    }
                    
                }
          
            }
        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId)
        }
        .toolbar {
            ToolbarItemGroup {
                Button { } label: {
                    Label("Upload file", systemImage: "square.and.arrow.up")
                }
                
                Button { } label: {
                    Label("Download file", systemImage: "square.and.arrow.down")
                }
                .disabled(selectedPath == nil)
                
                Button { } label: {
                    Label("Create folder", systemImage: "folder.badge.plus")
                }
                
                Button { } label: {
                    Label("Delete", systemImage: "xmark.bin")
                }
                .disabled(selectedPath == nil)
                
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
    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
