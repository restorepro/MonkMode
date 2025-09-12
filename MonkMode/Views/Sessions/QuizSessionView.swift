//
//  QuizSessionView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct QuizSessionView: View {
    @ObservedObject var vm: SessionManagerVM

    var body: some View {
        VStack(spacing: 16) {
            Text("Quiz mode placeholder")
                .font(.headline)
            Text("Plug your existing QuizViewModel here.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
