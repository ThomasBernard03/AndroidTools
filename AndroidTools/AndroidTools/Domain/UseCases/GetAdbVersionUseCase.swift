//
//  GetAdbVersionUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/05/2024.
//

import Foundation

class GetAdbVersionUseCase {
    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    func execute() -> Result<String, DisplayableError> {
        do {
            let version = try adbRepository.getVersion()
            return .success(version)
        }
        catch AdbError.notFound(let path) {
            return .failure(.error(message: "Adb path not found at \(path), you can change the path in settings"))
        }
        catch {
            return .failure(.error(message: "Unknown error"))
        }
    }
}
