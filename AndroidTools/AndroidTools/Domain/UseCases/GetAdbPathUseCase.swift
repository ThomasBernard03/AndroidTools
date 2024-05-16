//
//  GetAdbPathUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 16/05/2024.
//

import Foundation

class GetAdbPathUseCase {
    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    func execute() -> Result<String, DisplayableError> {
        do {
            let path = try adbRepository.getPath()
            return .success(path)
        }
        catch {
            return .failure(.error(message: "Can't find adb, set it manually"))
        }
    }
}
