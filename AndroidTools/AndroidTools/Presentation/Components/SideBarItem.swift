//
//  SideBarItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/04/2024.
//

import SwiftUI

struct SideBarItem: View {
    
    let label : String
    let systemImage : String
    
    var body: some View {
        Label(label, systemImage: systemImage)
            .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing:6) {
        SideBarItem(label:"Discover", systemImage: "star")
        SideBarItem(label:"Arcade", systemImage: "arcade.stick")
        SideBarItem(label:"Create", systemImage: "paintbrush")
    }

}
