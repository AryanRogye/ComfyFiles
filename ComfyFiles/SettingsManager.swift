//
//  SettingsManager.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import Foundation
import Combine
import SwiftUI
import CoreServices
import UniformTypeIdentifiers

@MainActor
final class SettingsManager: ObservableObject {
    
    @AppStorage("sectionHeight")
    var sectionHeight: Double = 30
    
    @AppStorage("fileSortKey")
    var fileSortKey: FileSortKey = .dateModified
    
    @AppStorage("sortDirection")
    var sortDirection: SortDirection = .forward
    
    public func makeSortOrder() -> [KeyPathComparator<ComfyFolder>] {
        switch fileSortKey {
        case .name:         return [KeyPathComparator(\.name, order: sortDirection.sortOrder)]
        case .size:         return [KeyPathComparator(\.size, order: sortDirection.sortOrder)]
        case .dateModified: return [KeyPathComparator(\.dateModified, order: sortDirection.sortOrder)]
        case .kind:         return [KeyPathComparator(\.kind, order: sortDirection.sortOrder)]
        }
    }
    public func persistSortOrder(_ order: [KeyPathComparator<ComfyFolder>]) {
        guard let first = order.first else { return }
        
        // Direction
        sortDirection = ((first.order == .forward)
                         ? SortDirection.forward
                         : SortDirection.reverse
        )
        
        // Key (match by keyPath)
        if first.keyPath == \ComfyFolder.name { fileSortKey = FileSortKey.name }
        else if first.keyPath == \ComfyFolder.dateModified { fileSortKey = FileSortKey.dateModified }
        else if first.keyPath == \ComfyFolder.kind { fileSortKey = FileSortKey.kind }
        else {
            // size needs special handling (see below)
            fileSortKey = FileSortKey.size
        }
    }
    
    func revertFolderHandlerToFinder() {
        let folderUTI = UTType.folder.identifier as CFString
        let finderID = "com.apple.finder" as CFString
        
        let status = LSSetDefaultRoleHandlerForContentType(
            folderUTI,
            .viewer,
            finderID
        )
        
        if status == noErr {
            print("✅ Finder restored as default")
        } else {
            print("❌ Failed:", status)
        }
    }
    func setAsDefaultFileManagerForFolders() {
        guard let bundleID = Bundle.main.bundleIdentifier as CFString? else { return }
        
        let folderUTI = UTType.folder.identifier as CFString // "public.folder"
        
        let status = LSSetDefaultRoleHandlerForContentType(
            folderUTI,
            .viewer,   // ✅ not .editor
            bundleID
        )
        
        if status == noErr {
            print("✅ Default handler set for folders")
        } else {
            print("❌ LS error:", status)
        }
    }
}


enum FileSortKey: String, CaseIterable {
    case name, size, dateModified, kind
}

enum SortDirection: String {
    case forward, reverse
    
    var sortOrder: SortOrder {
        switch self {
        case .forward:
            return .forward
        case .reverse:
            return .reverse
        }
    }
}
