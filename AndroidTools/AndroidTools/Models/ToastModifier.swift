//
//  ToastModifier.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 26/04/2024.
//

import Foundation
import SwiftUI

struct ToastModifier: ViewModifier {
  
  @Binding var toast: Toast?
  @State private var workItem: DispatchWorkItem?
  
  func body(content: Content) -> some View {
      ZStack {
          content
      }
      .frame(width: .infinity, height: .infinity)
      .overlay(alignment: .bottom, content: {
          mainToastView()
      })
      .animation(.spring(), value: toast)
      .onChange(of: toast) { value in
        showToast()
      }
  }
  
  @ViewBuilder func mainToastView() -> some View {
    if let toast = toast {
      VStack {
          Spacer()
        ToastView(
          style: toast.style,
          message: toast.message,
          width: toast.width
        )
        
      }
    }
  }
  
  private func showToast() {
    guard let toast = toast else { return }
    
    
    if toast.duration > 0 {
      workItem?.cancel()
      
      let task = DispatchWorkItem {
        dismissToast()
      }
      
      workItem = task
      DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }
  }
  
  private func dismissToast() {
    withAnimation {
      toast = nil
    }
    
    workItem?.cancel()
    workItem = nil
  }
}
