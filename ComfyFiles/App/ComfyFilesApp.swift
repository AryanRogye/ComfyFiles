//
//  ComfyFilesApp.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/30/26.
//

import SwiftUI

@main
struct ComfyFilesApp: App {
    
    @StateObject var settingsManager = SettingsManager()
    @State private var comfyFileManager = ComfyFileManager()
    @State private var comfyAppInfoManager = ComfyAppInfoManager()

    var body: some Scene {
        WindowGroup {
            ComfyFilesRoot(
                settingsManager: settingsManager,
                comfyFileManager: comfyFileManager,
                comfyAppInfoManager: comfyAppInfoManager
            )
            .onOpenURL { url in
                
                let comfyFolder = ComfyFolder(url)
                if comfyFolder.isFolder {
                    comfyFileManager.setSelectedFolder(comfyFolder)
                }
            }
        }
        .commands {
            ComfyFilesMenuBar()
        }
        
        Window("Settings", id: "settings-window") {
            SettingsView(settingsManager: settingsManager)
        }
        .defaultLaunchBehavior(.suppressed)
    }
}

struct FullDiskAccessRequestView: View {
    
    var comfyFileManager : ComfyFileManager
    var comfyAppInfoManager   : ComfyAppInfoManager
    
    var body: some View {
        VStack {
            Text("ComfyFiles Needs Full Disk Access To See Your Files And Folders")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            
            
            Button {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(comfyAppInfoManager.bundleLocation, forType: .string)
            } label: {
                Text("Copy App Path To Clipboard")
            }
            
            Button {
                comfyFileManager.openFullDiskAccessSettings()
            } label: {
                Text("Open Settings")
            }
            
            Button {
                comfyFileManager.checkFullDiskAccessStatus()
            } label: {
                Text("Check Again")
            }
        }
        .frame(width: 200, height: 300)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.5))
                .stroke(Color.accentColor, style: .init(lineWidth: 1.5))
        }
    }
}

struct ComfyFilesRoot: View {
    
    @ObservedObject var settingsManager: SettingsManager
    @Bindable var comfyFileManager: ComfyFileManager
    @Bindable var comfyAppInfoManager: ComfyAppInfoManager

    
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        if comfyFileManager.hasFullDiskAccess {
            NavigationStack {
                ComfyFiles()
                    .environment(comfyFileManager)
                    .environmentObject(settingsManager)
            }
        } else {
            FullDiskAccessRequestView(
                comfyFileManager: comfyFileManager,
                comfyAppInfoManager: comfyAppInfoManager
            )
        }
    }
}
