//
//  InstallerView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import SwiftUI

struct InstallerView: View {
    
    @State private var dropTargetted: Bool = false
    @ObservedObject private var viewModel = InstallerViewModel()
    
    
    var body: some View {
        
        
        
        RoundedRectangle(cornerRadius: 20)
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .frame(width: 200, height: 200)
            .onDrop(of: [.apk], isTargeted: $dropTargetted, perform: { providers in
                
                return true
            })
            .overlay {
                   if dropTargetted {
                       ZStack {
                           Color.black.opacity(0.5)

                           VStack(spacing: 8) {
                               Image(systemName: "plus.circle.fill")
                                   .font(.system(size: 40))
                               Text("Drop your apk here...")
                           }
                           .font(.title2)
                           .foregroundColor(.white)
                           .frame(maxWidth: 250)
                           .multilineTextAlignment(.center)
                       }
                       .cornerRadius(20)
                   }
               }
               .animation(.default, value: dropTargetted)
        
        
        Button {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.allowedContentTypes = [.apk]
            panel.begin { (response) in
                if response == .OK, let url = panel.url {
                    viewModel.installApk(path: url.path)
                }
            }
        } label: {
            Text("Open file explorer")
        }

        
        
    }
}

#Preview {
    InstallerView()
}
