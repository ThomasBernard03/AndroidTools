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
    private let getAdbPathUseCase : GetAdbPathUseCase = GetAdbPathUseCase()
    private let setAdbPathUseCase : SetAdbPathUseCase = SetAdbPathUseCase()
    
    var adbVersion = ""
    var adbPath = ""
    
    var toast : Toast? = nil
    
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
            toast = Toast(style: .error, message: "Error : \n\(message)")
        }
        }
    }
    
    func getAdbPath(){
        let result = getAdbPathUseCase.execute()
        
        switch(result){
        case .success(let path) : do {
            self.adbPath = path
        }
        case .failure(let message) : do {
            toast = Toast(style: .error, message: "Error : \n\(message)")
        }
        }
    }
    
    func setAdbPath(path : String){
       adbPath = setAdbPathUseCase.execute(path: path)
        getAdbVersion()
    }
    
    func resetAdbPath(){
       adbPath = setAdbPathUseCase.execute(path: nil)
        getAdbVersion()
    }
}
