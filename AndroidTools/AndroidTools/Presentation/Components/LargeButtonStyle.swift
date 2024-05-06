//
//  LargeButtonStyle.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/04/2024.
//

import Foundation
import SwiftUI

struct LargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.5) : Color.accentColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed) 
    }
}
