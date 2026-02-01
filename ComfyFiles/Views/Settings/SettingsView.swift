//
//  SettingsView.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    var body: some View {
        Form {
            Section("Controls") {
                
                HStack {
                    Button {
                        settingsManager.revertFolderHandlerToFinder()
                    } label: {
                        Text("Set Finder as Default File Manager")
                    }
                    Button {
                        settingsManager.setAsDefaultFileManagerForFolders()
                    } label: {
                        Text("Set As Default File Manager")
                    }
                }
                
                 LabeledContent("Padding Inside Section") {
                     Slider(
                        value: $settingsManager.sectionHeight,
                        in: 25...40,
                        step: 1
                     )
                     .frame(width: 180)
                 }
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}
