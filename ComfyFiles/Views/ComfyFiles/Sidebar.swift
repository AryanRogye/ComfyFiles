//
//  Sidebar.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/30/26.
//

import SwiftUI
import SwiftUI
import UniformTypeIdentifiers

struct Sidebar: View {
    
    @Bindable var comfyFileManager: ComfyFileManager
    @State private var dragging: ComfyFolder?
    
    var body: some View {
        List {
            home
            favorites
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    private var favorites: some View {
        ForEach(comfyFileManager.sidebarMainFolders) { item in
            SidebarRow(
                dragging: $dragging,
                item: item,
                comfyFileManager: comfyFileManager
            )
        }
    }
    
    private var home: some View {
        Button(action: { }) {
            Text("Home")
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var recents: some View {
        Button(action: {
            comfyFileManager.setSelectedRecents()
        }) {
            Text("Recents")
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarRow: View {
    
    @Binding var dragging: ComfyFolder?
    @State var item: ComfyFolder
    @Bindable var comfyFileManager: ComfyFileManager
    
    var body: some View {
        Button(action: {
            comfyFileManager.setSelectedFolder(item)
        }) {
            Text(item.url.lastPathComponent)
                .opacity(dragging == item ? 0 : 1.0)
                .animation(.easeInOut, value: dragging)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onDrag {
                    dragging = item
                    return NSItemProvider(object: item.id as NSString)
                }
                .onDrop(of: [UTType.text], delegate: SidebarReorderDropDelegate(
                    item: item,
                    items: $comfyFileManager.sidebarMainFolders,
                    dragging: $dragging
                ))
        }
        .buttonStyle(.plain)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(
            (comfyFileManager.selectedFolder?.title == item.name)
            ? AnyView(RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.12)))
            : AnyView(Color.clear)
        )
        .animation(.snappy, value: comfyFileManager.selectedFolder)
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    // MARK: - NSViewRepresentable
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
