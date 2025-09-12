//
//  MonkModeApp.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

@main
struct MonkModeApp: App {
    @StateObject private var vm = MonkViewModel()
    @StateObject var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(vm)
                .environmentObject(themeManager)
                                .preferredColorScheme(
                                    themeManager.selectedTheme == .system ? nil :
                                    (themeManager.selectedTheme == .dark ? .dark : .light)
                                )
        }
    }
}


