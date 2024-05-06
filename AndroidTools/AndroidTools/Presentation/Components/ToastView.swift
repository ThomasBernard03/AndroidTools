//
//  ToastView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 26/04/2024.
//

import Foundation
import SwiftUI

struct ToastView: View {
  
  var style: ToastStyle
  var message: String
  var width = CGFloat.infinity
  
  var body: some View {
      HStack(alignment: .center, spacing: 12) {
          if style == .loading {
              ProgressView {
                  Text(message)
              }
              .progressViewStyle(LinearProgressViewStyle())
          }
          else {
              Image(systemName: style.iconFileName)
                .foregroundColor(style.themeColor)
              Text(message)
                .font(Font.caption)
              
              Spacer()
          }
    }
    .padding()
    .frame(minWidth: 0, maxWidth: width)
    .background(Material.ultraThin)
    .cornerRadius(8)
    .shadow(radius: 2)
    .padding(16)
  }
}


#Preview {
    ToastView(style: .success, message: "Success")
    

}

#Preview {
    ToastView(style: .error, message: "Error")
}
