//
//  ThemeManager.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .system {
        didSet { objectWillChange.send() }
    }
    
    func colorScheme(for systemScheme: ColorScheme) -> ColorScheme {
        switch selectedTheme {
        case .system: return systemScheme
        case .light: return .light
        case .dark: return .dark
        case .gradient: return systemScheme  // still follow system for text, etc.
        }
    }
}
