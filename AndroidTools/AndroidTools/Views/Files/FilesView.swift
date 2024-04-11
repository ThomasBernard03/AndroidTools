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
    
    var body: some View {
        


        List(viewModel.root, children: \.childrens) { item in
            Text(item.description)
        }
        
        

        Text("Files view")
            .onAppear {
                viewModel.getFiles(deviceId: deviceId)
            }
    }
}

#Preview {
    FilesView(deviceId: "4dfda047")
}
