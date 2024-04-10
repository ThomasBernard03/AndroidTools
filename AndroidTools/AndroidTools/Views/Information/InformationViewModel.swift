//
//  InformationViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation


final class InformationViewModel: ObservableObject {
    @Published var device : DeviceDetail? = nil
    
    
    func getDeviceDetail(){
        device = AdbHelper().getDeviceInformation()
    }
}
