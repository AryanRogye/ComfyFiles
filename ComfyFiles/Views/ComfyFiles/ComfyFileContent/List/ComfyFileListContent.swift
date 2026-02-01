//
//  ComfyFileListContent.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//
import SwiftUI

struct ComfyFileListContent: View {
    
    @Bindable var comfyFileManager : ComfyFileManager
    @EnvironmentObject var settingsManager : SettingsManager
    
    @State private var sortOrder: [KeyPathComparator<ComfyFolder>] = []
    
    @State private var searchText: String = ""
    
    init(
        comfyFileManager: ComfyFileManager
    ) {
        self.comfyFileManager = comfyFileManager
        NSTableView.enableTableCatcherSwizzle()
    }
    
    var folderContents: [ComfyFolder] {
        if searchText.isEmpty {
            return comfyFileManager.selectedFolderContents
        } else {
            let search = searchText.lowercased()
            return comfyFileManager.selectedFolderContents.filter {
                
                let date = $0.dateModified?.finderStyleString() ?? ""
                
                return (
                    $0.name.lowercased().contains(search) ||
                    $0.url.path.lowercased().contains(search) ||
                    $0.kind.lowercased().contains(search) ||
                    date.lowercased().contains(search)
                )
            }
        }
    }

    var body: some View {
        Table(
            of: ComfyFolder.self,
            selection: $comfyFileManager.selectedItemsInListView,
            sortOrder: $sortOrder
        ) {
            /// Name + Icon
            TableColumn("Name") { file in
                HStack {
                    if file.isFile {
                        Image(systemName: "doc")
                            .foregroundStyle(Color.white)
                    } else {
                        Image(systemName: "folder")
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    Text(file.url.lastPathComponent)
                }
            }
            
            /// Size
            TableColumn(
                "Size",
                sortUsing: KeyPathComparator(\.sizeModifiedForSort, order: .forward)
            ) { file in
                Text(file.formattedSize)
            }
            
            /// Date Modified
            TableColumn(
                "Date Modified",
                sortUsing: KeyPathComparator(\.dateModifiedForSort, order: .forward)
            ) { file in
                if let date = file.dateModified {
                    Text(date.finderStyleString())
                } else {
                    Text("_")
                }
            }
            
            /// Kind
            TableColumn("Kind", value: \.kind)
        } rows: {
            ForEach(folderContents) { content in
                TableRow(content)
                    .draggable(content)
            }
            .dropDestination(for: ComfyFolder.self, action: { index, folder in
                print("Dropped: \(folder) on row: \(index)")
            })
        }
        .onDisappear {
            NSTableView.disableTableCatcherSwizzle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tableRowDoubleClicked)) { notif in
            let row = notif.userInfo?["row"] as? Int ?? -1
            if folderContents.indices.contains(row) {
                let doubleClickedItem = folderContents[row]
                if doubleClickedItem.isFolder {
                    self.comfyFileManager.setSelectedFolder(doubleClickedItem)
                } else {
                    self.comfyFileManager.open(doubleClickedItem)
                }
            }
        }
        .searchable(text: $searchText)
        .onAppear {
            sortOrder = settingsManager.makeSortOrder()
        }
        .onChange(of: sortOrder) { _, newValue in
            comfyFileManager.selectedFolderContents.sort(using: newValue)
            settingsManager.persistSortOrder(newValue)
        }
        .environment(\.defaultMinListRowHeight, settingsManager.sectionHeight)
    }
}
