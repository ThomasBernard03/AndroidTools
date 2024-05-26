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
                
                HStack {
                    Text("Resolving errors")
                        .font(.title2)
                    
                    Spacer()
                }
                
                Text("If your application displays strange results or does not work properly, check the adb path configured in the settings. You must provide a valid path. To find out where adb is installed on your Mac, open a terminal and enter the command: which adb")
                    .font(.subheadline)
                
                
                
            }
            .padding()
        }
        

        

        

        
    
    }
}

#Preview {
    HomeView()
}
