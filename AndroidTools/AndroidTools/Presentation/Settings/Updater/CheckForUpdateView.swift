//
//  CheckForUpdateView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import SwiftUI

struct CheckForUpdateView: View {
    @ObservedObject private var checkForUpdateViewModel : CheckForUpdateViewModel
    
    var body: some View {
        Button("Check for updates...") {
            //updater.checkForUpdates()
        }
    }
}
