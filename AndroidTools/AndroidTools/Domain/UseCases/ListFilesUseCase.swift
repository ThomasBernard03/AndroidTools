//
//  GetFileExplorerItems.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

class ListFilesUseCase {
    
    private let fileRepository : FileRepository = FileRepositoryImpl()
    
    func execute(deviceId : String, path : String = "") -> FileExplorerResultModel {
        let result = fileRepository.getFiles(deviceId: deviceId, path: path)
        return result
    }
}
