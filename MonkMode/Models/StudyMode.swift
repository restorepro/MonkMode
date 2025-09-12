//
//  StudyMode.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import Foundation

enum StudyMode: String, Codable, CaseIterable {
    case treadmill   // timed Q/A, treadmill-friendly
    case reading     // paragraph long-form
    case quiz        // scored multiple-choice or Q/A
    case free        // untimed, tap-to-reveal
}
