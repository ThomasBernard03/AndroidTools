//
//  HomeView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 20/04/2024.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        
        ScrollView {
            VStack(spacing: 20){
                HStack {
                    Text("Welcome to Android Tools 👋")
                        .font(.title)
                    
                    Spacer()
                }
                
                Text("Android tools is an open source project and is completely free to use. If you like the application, don't hesitate to share it and put a star on the [github repository](https://github.com/ThomasBernard03/AndroidTools).")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                
                
                HStack {
                    Text("Getting started")
                        .font(.title2)
                    
                    Spacer()
                }
                
                Text("To reduce the size of the application, we decided not to include ADB in the application (to avoid double installation on the Mac).  It is therefore up to the user to install ADB. ")
                    .font(.subheadline)
                
                
                
            }
            .padding()
        }
        

        

        

        
    
    }
}

#Preview {
    HomeView()
}
