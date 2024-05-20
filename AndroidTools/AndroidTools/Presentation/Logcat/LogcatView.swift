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
    

    var body: some View {
        ZStack(alignment:.bottom) {
            VStack {
                ScrollViewReader { proxy in
                    List(viewModel.logEntries){
                        LogEntryItem(date: $0.datetime, processId: $0.processID, threadId: $0.threadID, tag: $0.tag, level: $0.level, message: $0.message)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    

                    .onChange(of: viewModel.stickyList, { _, sticky in
                        if let lastId = viewModel.logEntries.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    })
                    .onChange(of: viewModel.logEntries, { _, _ in
                        if viewModel.stickyList {
                            if let lastId = viewModel.logEntries.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    })
                }
            }
            
            if viewModel.loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .offset(y:8)
            }
        }
        .onAppear {
            viewModel.getLogcat(deviceId: deviceId)
        }
        .toolbar {
            HStack {
                if viewModel.stickyList {
                    Button { viewModel.stickyList.toggle() } label: {
                        Label("Stick", systemImage: "arrow.down")
                    }
                    .background(.black.opacity(0.1))
                    .cornerRadius(6)
                    
                }
                else {
                    Button { viewModel.stickyList.toggle() } label: {
                        Label("Stick", systemImage: "arrow.down")
                    }
                }

                
                Button { } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(true)
                
                Button { } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(true)
                
                Button { viewModel.clearLogcat() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .disabled(viewModel.loading)
        }
        
    }
}

struct LogcatView_Previews: PreviewProvider {
    static var previews: some View {
        LogcatView(deviceId: "128967")
    }
}
