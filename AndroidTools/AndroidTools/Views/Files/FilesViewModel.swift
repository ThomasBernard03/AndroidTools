//
//  FilesViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/04/2024.
//

import Foundation

final class FilesViewModel : ObservableObject {
    
    @Published var root : [FileItem] = []
    
    func getFiles(deviceId : String, path : String = "/"){
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AdbHelper().getFiles(deviceId:deviceId, path: path)
            
            
            DispatchQueue.main.async {
                if path.isEmpty || path == "/"{
                    self.root = result
                }
                else {
                    if let index = self.root.firstIndex(where: { path == $0.path + $0.name}) {
                      var item = self.root[index]
                      item.childrens?.append(contentsOf: result)
                      self.root[index] = item // Update the array to trigger UI updates
                  }
                }
                
            }
        }

    }
    
}
