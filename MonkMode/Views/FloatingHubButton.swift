//
//  FloatingHubButton.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct FloatingHubButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}
