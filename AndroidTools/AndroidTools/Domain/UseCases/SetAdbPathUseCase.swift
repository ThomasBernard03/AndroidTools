//
//  SetAdbPathUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation

class SetAdbPathUseCase {
    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    func execute(path : String?) -> String {
        return adbRepository.setPath(path: path)
    }
}
