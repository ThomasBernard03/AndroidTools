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
        .onChange(of: toast) { _ in
            showToast()
        }
    }
  
    @ViewBuilder private func mainToastView() -> some View {
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
        workItem?.cancel() // Cancel any existing work item if the toast is updated
        
        if let toast = toast, toast.style != .loading {
            let task = DispatchWorkItem {
                dismissToast()
            }
        
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
        // If the style is .loading, do not schedule a dismissTask, so the toast will remain visible indefinitely
    }
  
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
    
        workItem?.cancel()
        workItem = nil
    }
}
