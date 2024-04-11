//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation

final class FilesViewModel : ObservableObject {
    
    @Published var root : [FileItem] = []
    
    func getFiles(deviceId : String, path : String = ""){
        var files = AdbHelper().getFiles(deviceId:deviceId, path: path)
        
        if path == "" {
            root = files
        }
    }
    
}
