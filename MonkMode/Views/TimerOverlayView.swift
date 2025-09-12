//
//  TimerOverlayView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct TimerOverlayView: View {
    @ObservedObject var vm: MonkViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("⏱ Timer Overlay").font(.title2).bold()

            Text("Cards Remaining: \(max(vm.cards.count - vm.currentIndex, 0))")
            Text("Time Left: \(vm.timeRemaining)s")
            Text("Score: \(vm.score)")

            Button("Close") {
                // sheet dismissal handled by parent
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
