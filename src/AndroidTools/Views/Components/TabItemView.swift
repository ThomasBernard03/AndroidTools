//
//  TabItemView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct TabItemView: View {
    
    let name : String
    let icon : String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))

            
            Text(name)
                .font(.system(size: 18))
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        
    }
}

struct TabItemView_Previews: PreviewProvider {
    static var previews: some View {
        
        VStack {
            TabItemView(name : "Logcat", icon: "text.redaction")
            TabItemView(name : "Files", icon: "doc.on.doc")
            TabItemView(name : "Informations", icon: "info.circle")
            TabItemView(name : "Miror", icon: "iphone.gen2.badge.play")
        }
        
    }
}
