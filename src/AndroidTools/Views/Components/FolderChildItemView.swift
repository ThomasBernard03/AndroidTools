//
//  FolderChildItemView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FolderChildItemView: View {
    
    private let adbHelper = AdbHelper()
    @State private var expanded = false
    
    @State private var childs : [File]? = nil
    
    let file : File

    
    var body: some View {
        VStack(spacing:5) {
            
            FolderItemView(name: file.name, expanded: expanded){
                expanded.toggle()
                adbHelper.getFiles(directory: file.path){ result in
                    childs = result
                }
            }


            
            if expanded {
                VStack {
                    if let child = childs {
                        VStack {
                            ForEach(child, id: \.name) { file in
                                if file.isFile {
                                    FileItemView(name: file.name)
                                }
                                else {
                                    FolderChildItemView(file: file)
                                }
                            }
                            
                        }
                    } else {
                        Text("Loading...")
                    }
                }
                .padding(.leading, 30)

            }
            

        }
    }
}

struct FolderChildItemView_Previews: PreviewProvider {
    static var previews: some View {
        let file = File(name: "data", modificationDate: Date(), isFile: false, size: 12, path: "/data")
        FolderChildItemView(file: file)
    }
}
