//
//  TerminalWindow.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 26/04/2024.
//

import SwiftUI

struct TerminalWindow: View {
    var commandText: String
    
    var body: some View {
        VStack(spacing:0) {
            // Barre de titre avec des boutons
            HStack {
                ZStack {
                    HStack {
                        Circle()
                            .foregroundColor(.red)
                            .frame(width: 12, height: 12)
                        Circle()
                            .foregroundColor(.yellow)
                            .frame(width: 12, height: 12)
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 12, height: 12)
                        Spacer()
                    }
                    Text("Terminal")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal)
            .frame(height: 24)
            .background(Color.gray.opacity(0.2))
            
            // Zone de contenu du terminal
            HStack {
                Text("$ > \(commandText)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
            }
            .background(Color.black)
        }
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

struct TerminalWindow_Previews: PreviewProvider {
    static var previews: some View {
        TerminalWindow(commandText: "ls -la")
    }
}
