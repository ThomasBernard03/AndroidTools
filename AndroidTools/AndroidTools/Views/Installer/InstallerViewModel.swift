//
//  InstallerViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

final class InstallerViewModel: ObservableObject {

    func installApk(path : String){
        
        print("Installing apk " + path)
        
        
        AdbHelper().installApk(path: path)
    }
}
