//
//  FileRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation

protocol FileRepository {
    /**
        List files for one device and one location
     
     - Parameters:
        - deviceId: The unique identifier of the device
        - path: The location of files
     */
    func getFiles(deviceId : String, path : String) -> FileExplorerResultModel
}
