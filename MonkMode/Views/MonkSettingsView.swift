//
//  MonkSettingsView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct MonkSettingsView: View {
    @ObservedObject var vm: MonkViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Timing") {
                    Stepper("Question Duration: \(vm.settings.questionDuration)s",
                            value: $vm.settings.questionDuration,
                            in: 3...30)
                    Stepper("Answer Duration: \(vm.settings.answerDuration)s",
                            value: $vm.settings.answerDuration,
                            in: 3...30)
                }

                Section("Options") {
                    Toggle("Shuffle Cards", isOn: $vm.settings.shuffle)
                    Toggle("Auto-Save Sessions", isOn: $vm.settings.autoSave)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
