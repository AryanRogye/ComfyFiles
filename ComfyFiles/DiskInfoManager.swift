//
//  DiskInfoManager.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 2/2/26.
//

import Foundation

struct DiskInfo {
    let total : Int64
    let free  : Int64
    
    init(total: Int64, free: Int64) {
        self.total = total
        self.free = free
    }
}

@Observable
@MainActor
final class DiskInfoManager {
    var diskInfo: DiskInfo = .init(total: 0, free: 0)
    let root = URL(fileURLWithPath: "/")
    
    init() {
        loadDiskInfo()
    }
    
    public func loadDiskInfo() {
        do {
            let values = try root.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
            
            guard
                let total : Int64 = values.volumeTotalCapacity.map(Int64.init),
                let free : Int64 = values.volumeAvailableCapacityForImportantUsage
            else { return  }
            
            self.diskInfo = DiskInfo(total: total, free: free)
        } catch {
            return
        }
    }
}
