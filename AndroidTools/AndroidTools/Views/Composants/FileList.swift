//
//  FileList.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/04/2024.
//

import SwiftUI

struct FileList: View {
    
    let files : [FileItem]
    let selection : Binding<String?>
    let onTap: (String) -> Void
    let onDoubleTap: (String) -> Void
    
    var body: some View {
        ForEach(files, id:\.name) { item in
            HStack {
                if item.childrens == nil {
                    FileRow(name:item.name)
                }
                else {
                    Label(item.name, systemImage:"folder")
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap("\(item.path)\(item.name)")
            }
            .onTapGesture(count: 2) {
                onDoubleTap("\(item.path)\(item.name)")
            }
            
            if !(item.childrens?.isEmpty ?? true) {
                FileList(files: item.childrens!, selection: selection, onTap: onTap, onDoubleTap: onDoubleTap)
                    .padding([.leading])
            }
        }
        
        
    }
}
