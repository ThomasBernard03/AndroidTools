//
//  InstallingView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 01/02/2025.
//

import Foundation
import SwiftUI

struct InstallingView: View {
    
    let path : URL
    
    @State private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text("Installing \(viewModel.applicationName)")
            Text(viewModel.message)

            Button("Fermer") {
                NSApp.windows.last?.close()
            }
        }
        .frame(width: 200, height: 100)
        .padding()
        .onAppear {
            Task {
                await viewModel.installApk(path: path)
            }
        }
    }
}
