//
//  EmulatorRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/08/2024.
//

import Foundation

protocol EmulatorRepository {
    /**
     Return list of all emulators installed on the mac
     
     - Returns: The list of all emulators
     */
    func getEmulators() -> [EmulatorListModel]
}
