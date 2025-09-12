//
//  ContentView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct ContentView: App {
    @StateObject private var vm = MonkViewModel()   // ✅ single shared instance

        var body: some Scene {
            WindowGroup {
                NavigationStack {
                    MonkView(vm: vm)
                }
            }
        }
}
