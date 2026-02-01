//
//  NSTableView+swizzle.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 2/1/26.
//

import ObjectiveC.runtime
import AppKit

extension Notification.Name {
    static let tableRowDoubleClicked = Notification.Name("tableRowDoubleClicked")
}

/*
 * NSTableView is whats under the hood for `Table`
 * so that means when we call Table, and we swizzle it in the view
 * we can catchMouseDown with events with count == 2
 *
 * Hook Into With:
 * .onReceive(
 *     NotificationCenter.default.publisher(
 *         for: .tableRowDoubleClicked
 *     )) { notif in
 *
 *      let row = notif.userInfo?["row"] as? Int ?? -1
 *      ...
 *      ..
 *  }
 */

extension NSTableView {
    
    private static var didSwizzle = false
    
    static func enableTableCatcherSwizzle() {
        guard !didSwizzle else { return }
        
        let cls: AnyClass = NSTableView.self
        
        let original = #selector(NSTableView.mouseDown(with:))
        let new      = #selector(test(with:))
        
        guard let f1 = class_getInstanceMethod(cls, original) else {
            print("NSTableView Swizzle | Couldnt Get Original Method")
            return
        }
        guard let f2 = class_getInstanceMethod(cls, new) else {
            print("NSTableView Swizzle | Couldnt Get New Method")
            return
        }
        
        method_exchangeImplementations(f1, f2)
        didSwizzle = true
    }
    
    static func disableTableCatcherSwizzle() {
        guard didSwizzle else { return }
        let cls: AnyClass = NSTableView.self
        
        let originalSel = #selector(NSTableView.mouseDown(with:))
        let swizzledSel = #selector(NSTableView.test(with:))
        
        guard
            let m1 = class_getInstanceMethod(cls, originalSel),
            let m2 = class_getInstanceMethod(cls, swizzledSel)
        else { return }
        
        method_exchangeImplementations(m1, m2) // swap back
        didSwizzle = false
    }
    
    @objc func test(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        
        if row != -1, event.clickCount == 2 {
            NotificationCenter.default.post(
                name: .tableRowDoubleClicked,
                object: self,
                userInfo: ["row": row]
            )
        }
        
        self.test(with: event)
    }
}
