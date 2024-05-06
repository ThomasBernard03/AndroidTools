//
//  DeviceRepository.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 06/05/2024.
//

import Foundation


protocol DeviceRepository {
    
    /**
     Return list of all connected Android devices
     
     - Returns: The list of Android devices, containing name and device Id
     */
    func getDevices() -> [DeviceListModel]
    
    
    /**
     Return a list of all information for one device
     
     - Parameters:
        - deviceId: The unique identifier of the device
     
     - Returns: A `DeviceInformationModel` A wrapper that contains all information
     */
    func getDevice(deviceId : String) -> DeviceInformationModel
    
    
    /**
     Restart a device
     
     - Parameters:
        - deviceId: The unique identifier of the device
     */
    func rebootDevice(deviceId : String)
}
