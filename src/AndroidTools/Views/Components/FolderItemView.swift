//
//  FolderView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FolderItemView: View {
    
    
    let name : String
    let expanded : Bool
    let onExpand : () -> Void
    
    @State private var hovered : Bool = false
    
    var body: some View {

            
        HStack {
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
                .frame(width: 20)
                .foregroundColor(Color("Dark"))
                .onTapGesture {
                    onExpand()
                }
                
            
            Image(systemName: "folder.fill")
                .foregroundColor(Color("Dark"))
            Text(name)
            Spacer()
        }
        .background(hovered ? Color.accentColor.opacity(0.2) : Color("Background"))
        .cornerRadius(5)
        .padding(.all, 0)
        .onTapGesture(count:2) {
            onExpand()
        }
        .onHover { inside in
            hovered = inside
        }
        .contextMenu{
            Menu {
                Button("File") {  }
                Button("Directory") {  }
           }
            label: {
               Label("New", systemImage: "ellipsis.circle")
           }
            
            Divider()
            
            Button("Download") {  }
            Button("Upload") {  }
            
            Divider()
            
            Button("Copy Path"){
                
            }
            
            Divider()
            
            Button("Delete"){
            }
        }

    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FolderItemView(name: "var", expanded: true){}
            FolderItemView(name: "bin", expanded: false){}
            FolderItemView(name: "home", expanded: true){}
        }
        
    }
}
