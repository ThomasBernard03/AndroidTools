//
//  CreateFolderUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 07/05/2024.
//

import Foundation

class CreateFolderUseCase {
    
    private let fileRepository : FileRepository = FileRepositoryImpl()
    
    func execute(deviceId : String, path : String, name : String) {
        fileRepository.createFolder(deviceId: deviceId, path: path, name: name)
    }
}
