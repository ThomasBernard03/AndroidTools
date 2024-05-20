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
    let level : LogLevel
    let message : String
    
    private var dateFormatter : DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }
    
    var body: some View {
        HStack(alignment:.top) {
            HStack {
                Text("\(date, formatter: dateFormatter)")
                    .frame(width: 90, alignment: .leading)
                
                Text("\(processId)-\(threadId)")
                    .frame(width: 90)
                
                Text(tag)
                    .frame(width:150, alignment: .leading)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 5)

            Text(level.rawValue)
                .frame(width: 26, height: 26)
                .background(level.color().opacity(0.3))
            
            
            Text(message)
                .foregroundColor(level.color())
                .textSelection(.enabled)
                .lineSpacing(8)
                .padding(.vertical, 5)
        }
    }
}

#Preview {
    VStack(alignment:.leading, spacing:0) {
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", level: .debug, message: "Here !!")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", level: .info, message: "Here !!")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", level: .error, message: "Error")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", level: .warning, message: "Here !!")
        
        LogEntryItem(date: Date.now, processId: 10755, threadId: 11341, tag: "EGL_emulation", level: .verbose, message: "Here !!")
    }

}
