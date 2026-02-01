//
//  ComfyFileManager.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/30/26.
//

import Foundation
import AppKit

enum Selection: Equatable {
    case folder(ComfyFolder)
    case recents
    
    var comfyFolder: ComfyFolder? {
        switch self {
        case .folder(let folder):
            return folder
        default:
            return nil
        }
    }
    
    var title: String {
        switch self {
        case .folder(let comfyFolder):
            return comfyFolder.name
        case .recents:
            return "Recents"
        }
    }
}

@Observable
@MainActor
final class ComfyFileManager {
    let fm = FileManager.default
    
    /// Sidebar Main Folders
    var sidebarMainFolders: [ComfyFolder] = []
    
    /// Selections
    var selectedFolder: Selection?
    var selectedFolderContents: [ComfyFolder] = []
    
    var selectedItemsInListView: Set<String> = []
    
    /// Permissions
    var hasFullDiskAccess: Bool = false
    
    /// Recents
    var recentContent: [ComfyFolder] = []
    var recentObservers: [NSObjectProtocol?] = []
    var recentsQuery: NSMetadataQuery?
    
    var backHistory: [ComfyFolder] = []
    var forwardHistory: [ComfyFolder] = []
    
    init() {
        self.reload()
        self.checkFullDiskAccessStatus()
    }
    
    @MainActor
    deinit {
        for observer in recentObservers {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        recentsQuery?.stop()
    }
    
}

// MARK: - Set Selected
extension ComfyFileManager {
    public func setSelectedRecents() {
        selectedFolderContents.removeAll()
        selectedFolderContents = recentContent
    }
    
    public func goBackPage() {
        
        guard
            let current = selectedFolder?.comfyFolder,
            let previous = backHistory.popLast()
        else {
            print("Couldnt Pop Back")
            return
        }
        
        forwardHistory.append(current)
        setSelectedFolder(previous, onUndo: true)
    }
    
    public func goForwardPage() {
        guard
            let current = selectedFolder?.comfyFolder,
            let next = forwardHistory.popLast()
        else { return }

        backHistory.append(current)
        setSelectedFolder(next, onUndo: true)
    }
    
    public func setSelectedFolder(_ folder: ComfyFolder, onUndo: Bool = false) {
        if !onUndo {
            if let selectedFolder {
                if let last = selectedFolder.comfyFolder {
                    backHistory.append(last)
                }
            }
        }
        
        self.selectedFolder = .folder(folder)
        selectedFolderContents.removeAll()
        
        do {
            let urls = try fm.contentsOfDirectory(
                at: folder.url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            
            selectedFolderContents = urls.map {
                return ComfyFolder($0)
            }
            
        } catch {
            print("Failed to load folder:", error)
        }
    }
}

// MARK: - File System Stuff
extension ComfyFileManager {
    internal func reload() {
        let newHome = ComfyFolder(fm.homeDirectoryForCurrentUser)
        
        // only include these if we have scoped access
        let desktopURL = fm.urls(for: .desktopDirectory, in: .userDomainMask).first
        let docsURL    = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let dlURL      = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first
        
        let newDesktop = desktopURL.map { ComfyFolder($0) }
        let newDocs    = docsURL.map { ComfyFolder($0) }
        let newDL      = dlURL.map { ComfyFolder($0) }
        
        let allNew = [newHome, newDesktop, newDL, newDocs].compactMap { $0 }
        
        let oldOrder = sidebarMainFolders
        
        sidebarMainFolders = oldOrder.compactMap { old in
            allNew.first { $0.url == old.url }
        }
        
        for folder in allNew {
            if !sidebarMainFolders.contains(where: { $0.url == folder.url }) {
                sidebarMainFolders.append(folder)
            }
        }
    }

    internal func observeRecentList() {
        let query = NSMetadataQuery()
        self.recentsQuery = query
        query.searchScopes = [NSMetadataQueryUserHomeScope]
        
        let days: TimeInterval = 7 * 24 * 60 * 60
        let cutoff = Date().addingTimeInterval(-days)
        
        query.predicate = NSPredicate(
            format: "%K >= %@",
            NSMetadataItemContentModificationDateKey,
            cutoff as NSDate
        )
        
        query.sortDescriptors = [
            NSSortDescriptor(
                key: NSMetadataItemContentModificationDateKey,
                ascending: false
            )
        ]
        
        query.start()
        
        let finishObs = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: .main
        ) { notification in
            guard let currentQuery = notification.object as? NSMetadataQuery else { return }
            if let results = currentQuery.results as? [NSMetadataItem] {
                DispatchQueue.main.async {
                    self.updateRecentsList(with: results)
                }
            }
        }
        
        let updateObs = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query,
            queue: .main
        ) { notification in
            guard let currentQuery = notification.object as? NSMetadataQuery else { return }
            if let results = currentQuery.results as? [NSMetadataItem] {
                DispatchQueue.main.async {
                    self.updateRecentsList(with: results)
                }
            }
        }
        
        recentObservers = [finishObs, updateObs]
    }
    
    internal func updateRecentsList(with results: [NSMetadataItem]) {
        var updatedComfyFolders: [ComfyFolder] = []
        for item in results {
            if let url = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                let fileURL = URL(fileURLWithPath: url)
                updatedComfyFolders.append(ComfyFolder(fileURL))
            }
        }
        
        recentContent = updatedComfyFolders
    }
}

// MARK: - Permissions
extension ComfyFileManager {
    
    func openFullDiskAccessSettings() {
        // This URL opens the Privacy & Security preference pane, specifically the Full Disk Access section
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FullDiskAccess") {
            NSWorkspace.shared.open(url)
        }
    }
    func checkFullDiskAccessStatus() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let desktopPath = homeDirectory.appendingPathComponent("Desktop")
        
        // Check if we can enumerate the directory without an error
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: desktopPath.path)
            self.hasFullDiskAccess = true
        } catch {
            // Access denied
            self.hasFullDiskAccess = false
        }
    }
}

