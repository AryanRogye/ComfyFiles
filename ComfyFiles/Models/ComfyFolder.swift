//
//  ComfyFolder.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 2/1/26.
//

import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct ComfyFolder: Identifiable, Hashable, Sendable, Transferable, Codable {
    var id : String { url.path }
    let url : URL
    
    var name: String {
        return url.lastPathComponent
    }
    
    var kind: String {
        guard let values = try? url.resourceValues(forKeys: [.contentTypeKey]) else { return "_" }
        
        if let type = values.contentType {
            if let kind = type.localizedDescription {
                return kind.capitalized
            }
        }
        return "_"
    }
    
    var dateModifiedForSort: Date {
        dateModified ?? .distantPast
    }
    
    var dateModified: Date? {
        let values = try? url.resourceValues(forKeys: [.attributeModificationDateKey, .contentModificationDateKey])
        
        let meta_data_date = values?.attributeModificationDate
        let content_data_date = values?.contentModificationDate
        
        if let meta_data_date , let content_data_date {
            /// whichever one is more recent is what we return
            return max(meta_data_date, content_data_date)
        }
        
        return meta_data_date ?? content_data_date
    }
    
    var formattedSize: String {
        guard let size else { return "_" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        
        return formatter.string(fromByteCount: Int64(size))
    }
    
    var sizeModifiedForSort: Int {
        return size ?? 0
    }
    
    var size: Int? {
        if isFile {
            
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return values?.fileSize
        }
        return nil
    }
    
    var isFile: Bool {
        (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
    }
    
    var isFolder: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    init(_ url: URL) {
        self.url = url
    }
    
    static var draggableType = UTType(exportedAs: "com.aryanrogye.ComfyFiles.ComfyFolder")
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: ComfyFolder.draggableType)
    }
}
