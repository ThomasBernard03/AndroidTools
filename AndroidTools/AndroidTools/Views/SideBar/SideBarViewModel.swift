//
//  SideBarViewModel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import Foundation

final class SideBarViewModel: ObservableObject {
    @Published var selectedDeviceId: String = ""
    @Published var devices: [Device] = []
    
    private let adbHelper = AdbHelper()

    func getAndroidDevices() {
        DispatchQueue.global(qos: .background).async {
            let devices = self.adbHelper.getDevices()
            
            DispatchQueue.main.async { [weak self] in
                self?.devices = devices
                if !devices.isEmpty && ((self?.selectedDeviceId.isEmpty) != nil) {
                    self?.selectedDeviceId = devices.first?.id ?? ""
                }
            }
        }
    }
}
