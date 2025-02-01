//
//  FloatingPanel.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 01/02/2025.
//


import SwiftUI
import AppKit

class FloatingPanel<Content: View>: NSPanel {
    
    init(view: () -> Content,
         contentRect: NSRect,
         backing: NSWindow.BackingStoreType = .buffered,
         defer flag: Bool = false
    ) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView], backing: backing, defer: flag)
        
        isFloatingPanel = true
        level = .floating
        
        collectionBehavior.insert(.fullScreenAuxiliary)
        
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        animationBehavior = .utilityWindow
     
        /// Set the content view.
        /// The safe area is ignored because the title bar still interferes with the geometry
        contentView = NSHostingView(rootView: view()
            .ignoresSafeArea()
            .environment(\.floatingPanel, self))
    }
}

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}
 
extension EnvironmentValues {
  var floatingPanel: NSPanel? {
    get { self[FloatingPanelKey.self] }
    set { self[FloatingPanelKey.self] = newValue }
  }
}
