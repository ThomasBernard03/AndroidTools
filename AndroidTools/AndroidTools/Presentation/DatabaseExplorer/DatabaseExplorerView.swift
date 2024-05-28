//
//  DatabaseExplorerView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 27/05/2024.
//

import SwiftUI

struct DatabaseExplorerView: View {
    
    let deviceId : String
    
    @StateObject private var viewModel = DatabaseExplorerViewModel()
    @AppStorage("packageName") private var packageName = ""
    
    var body: some View {
        ZStack(alignment:.bottom) {
            VStack {
                NavigationSplitView(
                    sidebar: {
                        if viewModel.selectedPackage == nil {
                            List(viewModel.packages.filter{ packageName.isEmpty || $0.contains(packageName  ) }, id: \.self, selection: $viewModel.selectedPackage){
                                Text($0)
                            }
                            .contextMenu(forSelectionType: String.self, menu: { _ in }) { selection in

                                
                            }
                            .onAppear {
                                viewModel.getPackages(deviceId: deviceId)
                            }
                        }
                        else {
                            List {
                                NavigationLink(destination: { DatabaseExplorerQueryView() }){
                                    SideBarItem(label: "Query", systemImage: "apple.terminal.fill")
                                }
                                Divider()
                                ForEach(viewModel.tables, id: \.self){ table in
                                    NavigationLink(destination: { DatabaseExplorerTableView(deviceId: deviceId, packageName: viewModel.selectedPackage!, table: table) }) {
                                        SideBarItem(label: table, systemImage: "tablecells.fill")
                                    }
                                }
                            }
                            .listStyle(SidebarListStyle())
                            .padding(.vertical)
                            .onAppear {
                                viewModel.getPackageDatabaseTables(deviceId: deviceId, packageName: viewModel.selectedPackage!)
                            }
                        }
                    },
                    detail: {
                    
                    }
                )
   
            }

            if viewModel.loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .offset(y:8)
            }
        }

        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    viewModel.goBack()
                } label: {
                    Label("Go back", systemImage: "chevron.left")
                }
                .disabled(viewModel.selectedPackage == nil)
            }
        }
        .searchable(text: $packageName, prompt: "Package name")
    }
}

#Preview {
    DatabaseExplorerView(deviceId: "123414")
}
