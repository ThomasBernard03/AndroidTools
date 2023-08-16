//
//  FolderView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FolderItemView: View {
    
    @State private var isExpanded = false
    let name : String
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.right")
                .frame(width: 30)
            Image(systemName: "folder.fill")
            Text(name)
            Spacer()
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FolderItemView(name: "var")
            FolderItemView(name: "bin")
            FolderItemView(name: "home")
        }
        
    }
}
