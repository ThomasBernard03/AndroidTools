//
//  SettingsViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/04/2024.
//

import Foundation
import Sparkle

@Observable
class SettingsViewModel : ObservableObject {
    let updaterController : SPUStandardUpdaterController
    private let getAdbVersionUseCase : GetAdbVersionUseCase = GetAdbVersionUseCase()
    
    var adbVersion : String = ""
    
    init(){
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    func checkForUpdates(){
        updaterController.updater.checkForUpdates()
    }
    
    func getAdbVersion(){
        adbVersion = ""
        adbVersion = getAdbVersionUseCase.execute()
    }
}
