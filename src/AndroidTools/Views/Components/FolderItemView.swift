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
    
    @State var hovered : Bool = false
    
    var body: some View {

            
        HStack {
            Image(systemName: expended ? "chevron.down" : "chevron.right")
                .frame(width: 20)
                .foregroundColor(Color("Dark"))
                
            
            Image(systemName: "folder.fill")
                .foregroundColor(Color("Dark"))
            Text(name)
            Spacer()
        }
        .background(hovered ? Color.accentColor.opacity(0.2) : Color("Background"))
        .cornerRadius(5)
        .padding(.all, 0)
        .onHover { inside in
            hovered = inside
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
