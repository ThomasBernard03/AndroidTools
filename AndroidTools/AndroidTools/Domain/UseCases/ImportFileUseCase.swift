//
//  ImportFileUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 07/05/2024.
//

import Foundation

class ImportFileUseCase {
    private let fileRepository : FileRepository = FileRepositoryImpl()
    
    func execute(deviceId : String, filePath : String, targetPath : String) {
        fileRepository.importFile(deviceId: deviceId, filePath: filePath, targetPath: targetPath)
    }
}
