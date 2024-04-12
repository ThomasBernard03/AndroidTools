//
//  FileItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/04/2024.
//

import SwiftUI

struct FileRow: View {
    
    let name : String
    
    var body: some View {
        Label {
            Text(name)
        } icon: {
            let fileExtension = name.substringAfterLast(".").replacingOccurrences(of: ".", with: "")
            Image(nsImage: NSWorkspace.shared.icon(forFileType: fileExtension))
                .resizable()
                .frame(width: 16, height: 16)
            
        }

    }
}

#Preview {
    FileRow(name:"hello.mp4")
}
