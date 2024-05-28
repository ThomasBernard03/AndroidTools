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
    
    var body: some View {
        ZStack(alignment:.bottom) {
            if viewModel.selectedPackage == nil {
                List(viewModel.packages, id: \.self, selection: $viewModel.selectedPackage){
                    Text($0)
                }
                .contextMenu(forSelectionType: String.self, menu: { _ in }) { selection in

                    
                }
            }
            else {
                VStack {
                    NavigationSplitView(
                        sidebar: {
                            List(viewModel.tables, id: \.self){ table in
                                NavigationLink(table) {
                                    DatabaseExplorerTableView(deviceId: deviceId, packageName: viewModel.selectedPackage!, table: table)
                                }
                            }
                            .listStyle(SidebarListStyle())
                        },
                        detail: {
                        
                        }
                    )
                }
                .onAppear {
                    viewModel.getPackageDatabaseTables(deviceId: deviceId, packageName: viewModel.selectedPackage!)
                }
            }

            
            if viewModel.loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .offset(y:8)
            }
        }
        .onAppear {
            viewModel.getPackages(deviceId: deviceId)
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
    }
}

#Preview {
    DatabaseExplorerView(deviceId: "123414")
}
