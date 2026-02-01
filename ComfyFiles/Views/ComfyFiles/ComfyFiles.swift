//
//  ComfyFiles.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/30/26.
//

import SwiftUI

struct ComfyFiles: View {
    
    @Environment(ComfyFileManager.self) var comfyFileManager
    
    @State var showSidebar = true
    @StateObject var comfyFilesVM = ComfyFilesViewModel()
    
    
    var body: some View {
        SidebarSplit(
            showSidebar: $showSidebar,
            sidebar: {
                Sidebar(comfyFileManager: comfyFileManager)
            },
            content: {
                ComfyFileContent(
                    showSidebar: $showSidebar,
                    comfyFileManager: comfyFileManager,
                    comfyFileVM: comfyFilesVM,
                )
            }
        )
    }
}
