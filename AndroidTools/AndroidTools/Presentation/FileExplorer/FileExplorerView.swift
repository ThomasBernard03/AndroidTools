//
//  FilesView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI
import UniformTypeIdentifiers.UTType

struct IdentifiableFileExplorerItem: Identifiable {
    let id: String
    let item: FileExplorerItem

    init(item: FileExplorerItem) {
        self.id = item.name
        self.item = item
    }
}


struct FilesView: View {
    
    let deviceId : String
    
    @State private var viewModel = FilesViewModel()
    @State private var selection: IdentifiableFileExplorerItem.ID? = nil
    
    private var itemDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    
    var body: some View {
        
        let items = (viewModel.fileExplorerResult?.childrens ?? []).map { item in
            IdentifiableFileExplorerItem(item: item)
        }
        
        var currentItem: FileExplorerItem? {
            return items.first { $0.id == selection }?.item
        }


        
        Table(of: IdentifiableFileExplorerItem.self, selection: $selection){
            TableColumn("Name") { wrapper in
                if let fileItem = wrapper.item as? FileItem {
                    FileRow(name: fileItem.name)
                }
                else {
                    Text(wrapper.item.name)
                }
            }
            
            TableColumn("Last Modified") { wrapper in
                if let fileItem = wrapper.item as? FileItem {
                    Text("\(fileItem.lastModificationDate, formatter: itemDateFormatter)")
                    // Text(fileItem.lastModificationDate, style: .date)
                } else {
                    EmptyView()
                }
            }
            .width(140)
            
            TableColumn("Size"){ wrapper in
                if let fileItem = wrapper.item as? FileItem {
                    Text(fileItem.size.toSize())
                }
                else {
                    EmptyView()
                }
            }
            .width(80)
        } rows: {
            ForEach(items, id: \.id){ wrapper in
                TableRow(wrapper)
                    .contextMenu {
                        Button("Rename") {
                            // TODO open editor in inspector
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            
                        }
                    }
                    
            }
        }
        .contextMenu(forSelectionType: String.self, menu: { _ in }) {_ in
            let currentItem = currentItem?.name
            if viewModel.fileExplorerResult?.fullPath.isEmpty ?? false {
                viewModel.getFiles(deviceId: deviceId, path: currentItem ?? "")
            }
            else {
                let path = "\(viewModel.fileExplorerResult?.fullPath ?? "")/\(currentItem ?? "")"
                viewModel.getFiles(deviceId: deviceId, path: path)
            }

        }
        .onAppear {
            viewModel.getFiles(deviceId: deviceId)
        }
        .onChange(of: deviceId) { _, newValue in
            viewModel.getFiles(deviceId: newValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { viewModel.getFiles(deviceId: deviceId, path: viewModel.fileExplorerResult?.path ?? "/") } label: {
                    Label("Go back", systemImage: "chevron.left")
                }
                .disabled(viewModel.loading || viewModel.fileExplorerResult?.name == "")
            }
        }
    }

}

#Preview {
    FilesView(deviceId: "4dfda047")
}
