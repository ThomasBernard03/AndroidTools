//
//  SettingsViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/04/2024.
//

import Foundation
import Sparkle

class SettingsViewModel {
    let updaterController : SPUStandardUpdaterController
    
    init(){
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    func checkForUpdates(){
        updaterController.updater.checkForUpdates()
    }
}
