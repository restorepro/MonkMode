//
//  MonkModeApp.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

@main
struct MonkModeApp: App {   // ✅ renamed from ContentView
    @StateObject private var vm = MonkViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MonkView(vm: vm)
            }
        }
    }
}


