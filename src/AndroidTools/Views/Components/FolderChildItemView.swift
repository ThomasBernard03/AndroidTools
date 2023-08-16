//
//  FolderChildItemView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FolderChildItemView: View {
    
    private let adbHelper = AdbHelper()
    @State private var isExpanded = false
    
    @State private var childs : [File]? = nil
    
    let file : File

    
    var body: some View {
        VStack {
            
            FolderItemView(name: file.name)
                .onTapGesture(count:2) {
                    isExpanded.toggle()
                    adbHelper.getFiles(directory: file.path){ result in
                        childs = result
                    }
                }

            
            if isExpanded {
                VStack {
                    if let child = childs {
                        ScrollView {
                            LazyVStack {
                                ForEach(child, id: \.name) { file in
                                    if file.isFile {
                                        FileItemView(name: file.name)
                                    }
                                    else {
                                        FolderChildItemView(file: file)
                                    }
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
        let file = File(name: "test", modificationDate: Date(), isFile: false, size: 12, path: "")
        FolderChildItemView(file: file)
    }
}
