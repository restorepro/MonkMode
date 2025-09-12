//
//  AppTheme.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark
    case gradient   // 🆕 add gradient option
    
    var id: String { rawValue }
}
