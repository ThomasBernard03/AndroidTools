//
//  DeviceDetail.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

struct DeviceInformationModel {
    let manufacturer : String // Ex : Samsung, Xiaomi
    let model : String // Ex : S24, A55
    let serialNumber : String
    
    let androidVersion : String
    
    let batteryInformation : BatteryInformation
    
    
    struct BatteryInformation {
        let charging : Bool
        let percentage : Int
    }
}
