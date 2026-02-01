//
//  ComfyAppInfoManager.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import Foundation

@Observable
@MainActor
final class ComfyAppInfoManager {
    
    var bundleLocation: String
    
    init() {
        self.bundleLocation = Bundle.main.bundleURL.path()
    }
}
