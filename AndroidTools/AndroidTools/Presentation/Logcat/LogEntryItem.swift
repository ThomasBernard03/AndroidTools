//
//  LogEntryItem.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 08/05/2024.
//

import SwiftUI

struct LogEntryItem: View {
    
    let date : Date
    let processId : Int
    let threadId : Int
    let tag : String
    let packageName : String
    let level : LogLevel
    let message : String
    
    private var dateFormatter : DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            Text("\(date, formatter: dateFormatter)")
                .frame(width: 120)
            
            Text("\(processId)-\(threadId)")
                .frame(width: 85)
            
            Text(tag)
                .frame(width:120)
            
            Text(packageName)
                .frame(width: 200)
            
            Text(level.rawValue)
                .frame(width: 26, height: 26)
                .background(level.backgroundColor())
                
                
            
            
            Text(message)
                .foregroundColor(level.backgroundColor())
                .fixedSize(horizontal: false, vertical:true)
        }
        .lineLimit(1)
    }
}

#Preview {
    VStack(alignment:.leading, spacing:0) {
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", packageName: "fr.thomasbernard03.rickandmorty", level: .debug, message: "Here !!")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", packageName: "fr.thomasbernard03.rickandmorty", level: .info, message: "Here !!")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", packageName: "fr.thomasbernard03.rickandmorty", level: .error, message: "Error")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", packageName: "fr.thomasbernard03.rickandmorty", level: .warning, message: "Here !!")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", packageName: "fr.thomasbernard03.rickandmorty", level: .verbose, message: "Here !!")
    }

}
