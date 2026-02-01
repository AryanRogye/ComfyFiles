//
//  ComfyFilesViewModel.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/31/26.
//

import Foundation
import SwiftUI
import Combine


enum ComfyFilesLayout: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    case list_with_preview = "List With Preview"
    case gallery = "Gallery"
    
    var icon: String {
        switch self {
        case .grid:
            "square.grid.2x2"
        case .list:
            "list.bullet"
        case .list_with_preview:
            "square.split.2x1"
        case .gallery:
            "rectangle.stack"
        }
    }
}

@MainActor
final class ComfyFilesViewModel: ObservableObject {
    
    @AppStorage("comfyfilesLayout")
    var layout: ComfyFilesLayout = .list
}
