//
//  Date+finderStyleString.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 2/1/26.
//

import Foundation

extension Date {
    
    func finderStyleString() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today at \(Date.timeFormatter.string(from: self))"
        }
        
        if calendar.isDateInYesterday(self) {
            return "Yesterday at \(Date.timeFormatter.string(from: self))"
        }
        
        return Date.fullFormatter.string(from: self)
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
    
    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
