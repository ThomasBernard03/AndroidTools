//
//  SideBarView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct SideBarView: View {
    
    @StateObject var viewModel = ViewModel()
    
    @State private var selection = "Red"
    let colors = ["Red", "Green", "Blue", "Black", "Tartan"]
    
    var body: some View {
        
        NavigationView {
            List {
                
                Picker("", selection: $selection) {
                    ForEach(colors, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                .padding([.leading], -14)
                .padding([.trailing], -6)
                
                NavigationLink(destination: InformationView()) {
                    Text("Informations")
                }
                
                NavigationLink(destination: FilesView()) {
                    Text("Files")
                }
                
                NavigationLink(destination: ScreenView()) {
                    Text("Screen")
                }
                
            }
            .listStyle(.sidebar)
        }

    }
}

#Preview {
    SideBarView()
}
