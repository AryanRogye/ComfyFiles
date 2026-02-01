//
//  ComfyFileContentToolbar.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import SwiftUI

struct ComfyFileContentToolbar: ToolbarContent {
    
    @Binding var showSidebar: Bool
    @ObservedObject var viewModel: ComfyFilesViewModel
    
    init(showSidebar: Binding<Bool>, viewModel: ComfyFilesViewModel) {
        self._showSidebar = showSidebar
        self.viewModel = viewModel
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            ToolbarNavigationBackButton()
        }
        ToolbarItem(placement: .secondaryAction) {
            ToolbarNavigationForwardButton()
        }
        ToolbarItem(placement: .primaryAction) {
            ToolbarLayoutPicker(layout: $viewModel.layout)
        }
        ToolbarSpacer()
        ToolbarItem(placement: .navigation) {
            ToolbarSidebarButton {
                showSidebar.toggle()
            }
        }
    }
}

private struct ToolbarNavigationForwardButton: View {
    @Environment(ComfyFileManager.self) var comfyFileManager
    
    var body: some View {
        Button {
            comfyFileManager.goForwardPage()
        } label: {
            Image(systemName: "chevron.right")
        }
        .disabled(comfyFileManager.forwardHistory.isEmpty)
    }
}

private struct ToolbarNavigationBackButton: View {
    
    @Environment(ComfyFileManager.self) var comfyFileManager
    
    var body: some View {
        Button {
            comfyFileManager.goBackPage()
        } label: {
            Image(systemName: "chevron.left")
        }
        .disabled(comfyFileManager.backHistory.isEmpty)
    }
}

private struct ToolbarSidebarButton: View {
    var onClick: () -> Void
    
    var body: some View {
        Button {
            onClick()
        } label: {
            Image(systemName: "sidebar.left")
        }
    }
}

private struct ToolbarLayoutPicker: View {
    @Binding var layout: ComfyFilesLayout
    
    var body: some View {
        Picker("", selection: Binding(
            get: { layout },
            set: { newValue in
                DispatchQueue.main.async {
                    layout = newValue
                }
            }
        )) {
            ForEach(ComfyFilesLayout.allCases, id: \.self) { layout in
                /// Button gets the toolbar to show up nicely, without it, its a menu
                Image(systemName: layout.icon)
                    .tag(layout)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }
}
