//
//  ContentView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Tab 1")
                .tabItem {
                    Label("Tab 1",
                          systemImage: "1.circle")
                }

            Text("Tab 2")
                    .tabItem {
                        Label("Tab 2",
                              systemImage: "2.circle")
                    }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
