//
//  Item.swift
//  SwiftLogParser
//
//  Created by zhubiao07 on 2025/9/5.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
