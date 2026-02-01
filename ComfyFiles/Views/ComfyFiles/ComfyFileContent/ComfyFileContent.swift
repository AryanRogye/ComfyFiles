//
//  ComfyFileContent.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import SwiftUI
import Loupe

struct ComfyFileContent: View {
    
    @Binding var showSidebar: Bool
    @Bindable var comfyFileManager : ComfyFileManager
    @ObservedObject var comfyFileVM : ComfyFilesViewModel
    
    var body: some View {
        Group {
            switch comfyFileVM.layout {
            case .grid:
                Text("not yet implemented")
            case .list:
                ComfyFileListContent(comfyFileManager: comfyFileManager)
            case .list_with_preview:
                Text("not yet implemented")
            case .gallery:
                Text("not yet implemented")
            }
        }
        .navigationTitle(comfyFileManager.selectedFolder?.title ?? "ComfyFiles")
        .toolbar {
            ComfyFileContentToolbar(
                showSidebar: $showSidebar,
                viewModel: comfyFileVM
            )
        }
    }
}

