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
    
    @AppStorage("packageName") private var packageName = ""
    @AppStorage("logcatSticky") private var logcatSticky = true
    
    
    var packagesSearch : [String] {
        if self.packageName.isEmpty {
            return Array(viewModel.packages.prefix(5))
        }
        else {
            return Array(viewModel.packages.filter { $0.contains(packageName)}.prefix(5))
        }
    }
    

    var body: some View {
        ZStack(alignment:.bottom) {
            VStack {
                ScrollViewReader { proxy in
                    List(viewModel.logEntries){
                        LogEntryItem(date: $0.datetime, processId: $0.processID, threadId: $0.threadID, tag: $0.tag, level: $0.level, message: $0.message)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    .onChange(of: logcatSticky){ old, new in
                        if let lastId = viewModel.logEntries.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }

                    .onChange(of: viewModel.logEntries) { _, _ in
                        if logcatSticky {
                            if let lastId = viewModel.logEntries.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            
            if viewModel.loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .offset(y:8)
            }
        }
        .onChange(of: packageName){ oldValue, newValue in
            if newValue.isEmpty {
                viewModel.getLogcat(deviceId: deviceId, packageName: "")
            }
        }
        .onAppear {
            viewModel.getLogcat(deviceId: deviceId, packageName: packageName)
            viewModel.getPackages(deviceId: deviceId)
        }
        .toolbar {
            HStack {
                Button { logcatSticky.toggle() } label: {
                    Label("Stick", systemImage: "arrow.down")
                }
                .background(logcatSticky ? .black.opacity(0.1) : .clear)
                .cornerRadius(6)

                
                Button { viewModel.restartLogcat(deviceId: deviceId, packageName: packageName) } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.paused)
                
                Button { viewModel.pauseResumeLogcat(deviceId: deviceId, packageName: packageName) } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .background(viewModel.paused ? .black.opacity(0.1) : .clear)
                .cornerRadius(6)
                
                Button { viewModel.clearLogcat(deviceId: deviceId) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .disabled(viewModel.loading)
        }
        .searchable(text: $packageName, prompt: "Package name")
        .searchSuggestions {
            ForEach(packagesSearch, id: \.self){ package in
                Text(package)
                    .searchCompletion(package)
                    .onTapGesture {
                        packageName = package
                        viewModel.getLogcat(deviceId: deviceId, packageName: package)
                    }
            }
        }
    }
}

struct LogcatView_Previews: PreviewProvider {
    static var previews: some View {
        LogcatView(deviceId: "128967")
    }
}
