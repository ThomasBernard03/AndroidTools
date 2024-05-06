//
//  SideBarViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

@Observable
final class SideBarViewModel: ObservableObject {
    var selectedDevice: DeviceListModel? = nil
    var devices: [DeviceListModel] = []
    
    private let adbHelper = AdbHelper()

    func getAndroidDevices() {
        DispatchQueue.global(qos: .background).async {
            let devices = self.adbHelper.getDevices()
            
            DispatchQueue.main.async { [weak self] in
                self?.devices = devices
                if !devices.isEmpty && self?.selectedDevice == nil {
                    self?.selectedDevice = devices.first!
                }
            }
        }
    }
}
