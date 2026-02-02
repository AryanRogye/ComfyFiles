//
//  SidebarReorderDropDelegate.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 2/2/26.
//

import SwiftUI

struct SidebarReorderDropDelegate: DropDelegate {
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
