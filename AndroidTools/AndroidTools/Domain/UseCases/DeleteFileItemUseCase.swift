//
//  DeleteFileItemUseCase.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 07/05/2024.
//

import Foundation

class DeleteFileItemUseCase {
    private let fileRepository : FileRepository = FileRepositoryImpl()
    
    func execute(deviceId : String, path : String) {
        fileRepository.deleteFileItem(deviceId: deviceId, path: path)
    }
}
