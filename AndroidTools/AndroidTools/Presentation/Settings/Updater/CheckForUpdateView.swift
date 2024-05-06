//
//  CheckForUpdateView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import SwiftUI
import Sparkle

struct CheckForUpdateView: View {
    @ObservedObject private var checkForUpdateViewModel : CheckForUpdateViewModel
    private let updater : SPUUpdater
    
    init(updater : SPUUpdater){
        self.updater = updater
        self.checkForUpdateViewModel = CheckForUpdateViewModel(updater: updater)
    }
    
    var body: some View {
        Button("Check for updates...") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdateViewModel.canCheckForUpdate)
    }
}
