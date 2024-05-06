//
//  CircleWavesAnimation.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import SwiftUI

struct CircleWavesAnimation: View {
    
    @State private var scale: [Double] = [1, 1, 1, 1, 1, 1]
    @State private var opacity: [Double] = [1, 1, 1, 1, 1, 1]
    
    var body: some View {
        ForEach(0..<6, id: \.self) { index in
            Circle()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
                .scaleEffect(scale[index])
                .opacity(opacity[index])
                .animation(
                    Animation.easeOut(duration: 5).repeatForever(autoreverses: false).delay(Double(index)),
                    value: scale[index]
                )
                .onAppear {
                    scale[index] = 5
                    opacity[index] = 0
                }
        }
    }
}

#Preview {
    ZStack {
        CircleWavesAnimation()
    }.frame(width: 300, height: 300)
}
