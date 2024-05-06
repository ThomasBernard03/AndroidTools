//
//  CheckForUpdateViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/04/2024.
//

import Foundation
import SwiftUI
import Sparkle

final class CheckForUpdateViewModel : ObservableObject {
    @Published var canCheckForUpdate = false
    
    init(updater : SPUUpdater){
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdate)
    }
}
