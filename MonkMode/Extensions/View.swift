//
//  View.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

extension View {
    func appBackground(theme: ThemeManager) -> some View {
        self.background(
            Group {
                if theme.selectedTheme == .gradient {
                    AppGradients.purpleBlue.ignoresSafeArea()
                } else {
                    AppColors.background.ignoresSafeArea()
                }
            }
        )
    }
}
