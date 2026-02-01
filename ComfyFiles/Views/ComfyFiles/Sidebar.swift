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
            Button(action: {
                comfyFileManager.setSelectedRecents()
            }) {
                Text("Recents")
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            ForEach(comfyFileManager.sidebarMainFolders) { item in
                SidebarRow(
                    dragging: $dragging,
                    item: item,
                    comfyFileManager: comfyFileManager
                )
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
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

private struct SidebarReorderDropDelegate: DropDelegate {
    let item: ComfyFolder
    @Binding var items: [ComfyFolder]
    @Binding var dragging: ComfyFolder?
    
    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != item,
              let from = items.firstIndex(of: dragging),
              let to = items.firstIndex(of: item)
        else { return }
        
        withAnimation(.snappy) {
            items.move(fromOffsets: IndexSet(integer: from),
                       toOffset: to > from ? to + 1 : to)
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        DispatchQueue.main.async {
            dragging = nil
        }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
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
