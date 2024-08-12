//
//  EmulatorView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/08/2024.
//

import SwiftUI

struct EmulatorView: View {
    
    let emulatorName : String
    
    var body: some View {
        Text(emulatorName)
    }
}

#Preview {
    EmulatorView(emulatorName: "Pixel_3_API_24")
}
