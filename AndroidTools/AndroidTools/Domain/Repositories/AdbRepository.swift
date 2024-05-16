//
//  AdbRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation

protocol AdbRepository {
    
    func runAdbCommand(_ command: String) throws -> String
    
    
    func getVersion() throws -> String
}
