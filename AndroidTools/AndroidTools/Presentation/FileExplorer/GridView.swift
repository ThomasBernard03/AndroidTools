//
//  GridView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 07/05/2024.
//

import SwiftUI

struct GridView: View {
    
    @Binding var selection: IdentifiableFileExplorerItem.ID?
    let items: [IdentifiableFileExplorerItem]
    let fileExplorerResult : FileExplorerResultModel
    let onDeleteFileItem : () -> Void
    let onFetchFiles: (String) -> Void
    
    private let adaptiveColumn = [GridItem(.adaptive(minimum: 200))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumn, spacing: 20){
                ForEach(items) { wrapper in
                    HStack (alignment:.center){
                        if let file = wrapper.item as? FileItem {
                            let fileExtension = file.name.substringAfterLast(".").replacingOccurrences(of: ".", with: "")
                            Image(nsImage: NSWorkspace.shared.icon(forFileType: fileExtension))
                                .resizable()
                                .frame(width: 32, height: 32)
                                .scaledToFit()
                        }
                        else {
                            Image(systemName: "folder")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .scaledToFit()
                        }
                        
                        VStack {
                            Text(wrapper.item.name)
                            
                            if let fileItem = wrapper.item as? FileItem {
                                Text(fileItem.size.toSize())
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(height: 60)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.gray, lineWidth: 1)
                    )
                    
                }
            }
            .padding()
        }
    }
}
