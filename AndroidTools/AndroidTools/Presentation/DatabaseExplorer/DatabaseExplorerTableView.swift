//
//  DatabaseExplorerTableView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 28/05/2024.
//

import SwiftUI

struct DatabaseExplorerTableView: View {
    
    @StateObject private var viewModel = DatabaseExplorerTableViewModel()
    
    let deviceId : String
    let packageName : String
    let table : String
    
    var body: some View {
        Text("")
        .onAppear {
            viewModel.getTable(deviceId: deviceId, packageName: packageName, table: table)
        }
    }
}

#Preview {
    DatabaseExplorerTableView(deviceId: "", packageName: "", table: "")
}
