//
//  ApplicationSettingsViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/05/2024.
//

import Foundation
import Sparkle

@Observable
class ApplicationSettingsViewModel : ObservableObject {
    let updaterController : SPUStandardUpdaterController
    private let getAdbVersionUseCase : GetAdbVersionUseCase = GetAdbVersionUseCase()
    var adbVersion = ""
    
    init(){
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    func checkForUpdates(){
        updaterController.updater.checkForUpdates()
    }
    
    func getAdbVersion(){
        adbVersion = ""
        let result = getAdbVersionUseCase.execute()
        
        switch(result){
        case .success(let version) : do {
            self.adbVersion = version
        }
        case .failure(let message) : do {
            // TODO diplay error
        }
        }
    }
}
