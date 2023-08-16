//
//  FileItemView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct FileItemView: View {
    let name : String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
            Text(name)
            Spacer()
        }
        .padding(.leading, 30)
        
    }
}

struct FileItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FileItemView(name: "test.realm")
            FileItemView(name: "12032002.log")
            FileItemView(name: "lib.jar")
        }
        
    }
}
