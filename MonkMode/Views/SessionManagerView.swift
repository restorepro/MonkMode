//
//  SessionManagerView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct SessionManagerView: View {
    @StateObject var vm: SessionManagerVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Top bar
            HStack {
                Button("Close") {
                    vm.stop()
                    dismiss()
                }
                Spacer()
                Text(vm.mode.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text("Progress \(min(vm.currentIndex + 1, vm.cards.count))/\(vm.cards.count)")
                    .font(.subheadline)
            }
            .padding()

            Divider()

            // Mode-specific content
            Group {
                switch vm.mode {
                case .treadmill: TreadmillSessionView(vm: vm)
                case .reading:   ReadingSessionView(vm: vm)
                case .quiz:      QuizSessionView(vm: vm)
                case .free:      FreeStudyView(vm: vm)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}
