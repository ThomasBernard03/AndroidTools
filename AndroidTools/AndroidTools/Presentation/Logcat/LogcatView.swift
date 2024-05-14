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
                HStack {
                    Menu(viewModel.filterPackage ?? "All packages") {
                        Button("Display all packages") {
                            viewModel.filterPackage = nil
                        }
                        
                        Divider()
                        
                        ForEach(Array(viewModel.pidToPackageMap.keys), id: \.self) { pid in
                            if let packageName = viewModel.pidToPackageMap[pid] {
                                Button("\(packageName) (\(pid))") {
                                    // Mise à jour du filtre pour afficher uniquement les logs de ce package
                                    viewModel.filterPackage = packageName
                                }
                            }
                        }
                        
          
                    }

                    
                    TextField("Package", text: $viewModel.package)
                    
                    

                }
                .padding()
        
                ScrollViewReader { proxy in
                    List(viewModel.logEntries){
                        LogEntryItem(date: $0.datetime, processId: $0.processID, threadId: $0.threadID, tag: $0.tag, level: $0.level, message: $0.message)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    .onChange(of: viewModel.logEntries, { oldValue, newValue in
                        if let lastId = viewModel.logEntries.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
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
