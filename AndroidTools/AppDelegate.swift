//
//  AppDelegate.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 01/02/2025.
//
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { url in
            let mouseLocation = NSEvent.mouseLocation

            let panel = FloatingPanel(
                view: { return InstallingView(path:url) },
                contentRect: NSRect(
                    origin: CGPoint(x: mouseLocation.x, y: mouseLocation.y),
                    size: CGSize()
                )
            )
            panel.makeKeyAndOrderFront(nil)
        }
    }
}
