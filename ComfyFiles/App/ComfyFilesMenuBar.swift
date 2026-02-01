//
//  ComfyFilesMenuBar.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import SwiftUI

struct ComfyFilesMenuBar: Commands {
    
    @Environment(\.openWindow) var openWindow
    
    var body: some Commands {
        /// Name of Project "ComfyEditor"
        CommandGroup(replacing: .appSettings) {
            /// Settings
            Button {
                openWindow(id: "settings-window")
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
