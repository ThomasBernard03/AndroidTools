//
//  SideBarView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/08/2023.
//

import SwiftUI

struct SideBarView : View {
    @State var selected = "Home"
    @Namespace var animation
    var body: some View {
        HStack(spacing: 0){
            
            VStack(spacing: 22){
                
                
                Group{
                
                    
                    // Tab Button...
                    
                    SideBarItemView(image: "house.fill", title: "Home", selected: $selected, animation: animation)
                    
                    SideBarItemView(image: "folder", title: "File explorer", selected: $selected, animation: animation)
                    
                    SideBarItemView(image: "text.alignleft", title: "Logcat", selected: $selected, animation: animation)
                    
                    SideBarItemView(image: "info.circle", title: "Informations", selected: $selected, animation: animation)

                    SideBarItemView(image: "arrow.turn.up.forward.iphone", title: "Steam", selected: $selected, animation: animation)
                }
                
                Spacer()
            }
            
            Divider()
                .offset(x: -2)
        }
        // Side Bar Default Size...
        .frame(width: 240)
    }
}


