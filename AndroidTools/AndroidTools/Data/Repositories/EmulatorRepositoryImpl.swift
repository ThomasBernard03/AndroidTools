//
//  EmulatorRepositoryImpl.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/08/2024.
//

import Foundation

class EmulatorRepositoryImpl : EmulatorRepository {
    
    private var shellHelper : ShellHelper = ShellHelper()
    
    func getEmulators() -> [EmulatorListModel] {
        let emulators = shellHelper.runAdbCommand("cd /Users/thomasbernard/Library/Android/sdk/emulator; ./emulator -list-avds").components(separatedBy: .newlines)
            .filter({ (id) -> Bool in
                !id.isEmpty
            })
            .map { (name) -> EmulatorListModel in
                EmulatorListModel(id: name, name: name)
            }
        
        return emulators
    }
    
    
}
