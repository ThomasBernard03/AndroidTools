//
//  ApplicationSettingsViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 12/05/2024.
//

import Foundation

@Observable
class ApplicationSettingsViewModel : ObservableObject {
    
    private let getAdbVersionUseCase : GetAdbVersionUseCase = GetAdbVersionUseCase()
    private let getAdbPathUseCase : GetAdbPathUseCase = GetAdbPathUseCase()
    private let setAdbPathUseCase : SetAdbPathUseCase = SetAdbPathUseCase()
    
    var adbVersion = ""
    var adbPath = ""
    
    var toast : Toast? = nil
    

    
    func checkForUpdates(){
        // updaterController.updater.checkForUpdates()
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
