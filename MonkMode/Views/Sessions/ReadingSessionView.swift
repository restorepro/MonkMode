//
//  ReadingSessionView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct ReadingSessionView: View {
    @ObservedObject var vm: SessionManagerVM

    var body: some View {
        ScrollView {
            // Simple: show answers as paragraphs (replace with your paragraph source)
            Text(vm.cards.map { $0.answer }.joined(separator: "\n\n"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}
