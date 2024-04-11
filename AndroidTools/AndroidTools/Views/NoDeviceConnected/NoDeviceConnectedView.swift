//
//  NoDeviceConnectedView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import SwiftUI

struct NoDeviceConnectedView: View {
    
    let action: () -> Void
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        
        Button {
            action()
        } label: {
            Text("Refresh")
        }

    }
}

#Preview {
    NoDeviceConnectedView(){
        
    }
}
