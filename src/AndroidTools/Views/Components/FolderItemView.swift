//
//  FolderView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FolderItemView: View {
    
    
    let name : String
    let expended : Bool
    
    var body: some View {
        HStack {
            Image(systemName: expended ? "chevron.down" : "chevron.right")
                .frame(width: 20)
            Image(systemName: "folder.fill")
            Text(name)
            Spacer()
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FolderItemView(name: "var", expended: true)
            FolderItemView(name: "bin", expended: false)
            FolderItemView(name: "home", expended: true)
        }
        
    }
}
