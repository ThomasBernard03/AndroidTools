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
                if selectedPath == path {
                    selectedPath = nil
                    if let index = viewModel.root.firstIndex(where: { path == $0.fullPath}) {
                        var item = viewModel.root[index]
                        item.childrens?.removeAll()
                        viewModel.root[index] = item 
                    }
                }
                else {
                    selectedPath = path
                    if path.last == "/" {
                        viewModel.getFiles(deviceId: deviceId, path: path)
                    }
                    
                }
            } onDoubleTap: { path in
                selectedPath = path
                if path.last == "/" {
                    viewModel.getFiles(deviceId: deviceId, path: path)
                }
            }
        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId)
        }
        .toolbar(content: {
            Button {
                viewModel.getFiles(deviceId: deviceId)
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            
            Button {
            } label: {
                Label("Create folder", systemImage: "folder.badge.plus")
            }
            
            TextField("Search a file", text: $searchQuery)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .frame(minWidth: 200)

        })
    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
