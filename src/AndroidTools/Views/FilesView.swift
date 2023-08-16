//
//  FilesView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FilesView: View {
    
    @State var files : [File]? = nil
    
    private let adbHelper = AdbHelper()
    
    var body: some View {
        ZStack {
            
            if let files = files {
                ScrollView {
                    LazyVStack {
                        ForEach(files, id: \.path) { file in
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
        .onAppear {
            adbHelper.getFiles(){ result in
                files = result
            }
        }
        
    }
}

struct FilesView_Previews: PreviewProvider {
    static var previews: some View {
        FilesView()
    }
}
