//
//  LogcatView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 08/05/2024.
//

import SwiftUI

struct LogcatView: View {
    let deviceId: String
    
    @StateObject private var viewModel = LogcatViewModel()
    
    private func dateStyleFormatter() -> Date.FormatStyle {
        return Date.FormatStyle(date: .numeric, time: .standard)
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Package", text: $viewModel.package)
            }
            
//            Table(viewModel.logEntries){
//                TableColumn("Date") { entry in
//                    Text("\(entry.datetime.ISO8601Format())")
//                }
//                TableColumn("ProcessId-ThreadId") { entry in
//                    Text("\(entry.processID)-\(entry.threadID)")
//                }
//                TableColumn("Tag") { entry in
//                    Text(entry.tag)
//                }
//                TableColumn("Package") { entry in
//                    Text(entry.packageName)
//                }
//                TableColumn("Level") { entry in
//                    Text(entry.level.rawValue)
//                }
//                TableColumn("Message") { entry in
//                    Text(entry.message)
//                }
//            }

                List(viewModel.logEntries){
                    LogEntryItem(date: $0.datetime, processId: $0.processID, threadId: $0.threadID, tag: $0.tag, packageName: $0.packageName, level: $0.level, message: $0.message)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            

        }
        .onAppear {
            viewModel.getLogcat(deviceId: deviceId)
        }
        .toolbar {
            Button { } label: {
                Label("Stick", systemImage: "arrow.down")
            }
            
            Button { } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            
            Button { } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            
            Button { } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
    }
}

struct LogcatView_Previews: PreviewProvider {
    static var previews: some View {
        LogcatView(deviceId: "128967")
    }
}
