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
    @State private var searchValue : String = ""
    
    var body: some View {
        


        List(viewModel.root, children: \.childrens) { item in
            
            if item.childrens == nil {

                Label(title: {Text(item.name)}) {
                    let fileExtension = item.name.substringAfterLast(".").replacingOccurrences(of: ".", with: "")
                    Image(nsImage: NSWorkspace.shared.icon(forFileType: fileExtension))
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            else {
                Label(item.name, systemImage: "folder")
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
            
            TextField("Search a file", text: $searchValue)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .frame(minWidth: 200)

        })
    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
