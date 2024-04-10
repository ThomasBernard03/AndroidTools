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

    func getAndroidDevices() {
        DispatchQueue.global(qos: .background).async {
            let devices = AdbHelper().getDevices()
            
            DispatchQueue.main.async { [weak self] in
                self?.devices = devices
                if !devices.isEmpty && ((self?.selectedDeviceId.isEmpty) != nil) {
                    self?.selectedDeviceId = devices.first?.id ?? ""
                }
            }
        }
    }
}
