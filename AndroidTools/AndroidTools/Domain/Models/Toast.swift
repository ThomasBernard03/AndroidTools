//
//  Toast.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 26/04/2024.
//

import Foundation

struct Toast: Equatable {
  var style: ToastStyle
  var message: String
  var duration: Double = 3
  var width: Double = .infinity
}
