//
//  SessionService.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

@MainActor
final class SessionService: ObservableObject {
    static let shared = SessionService()
    @Published private(set) var sessions: [StudySession] = []

    private let fileName = "Sessions.json"

    private init() { loadFromDisk() }

    func addSession(_ session: StudySession) {
        sessions.append(session)
        save()
    }

    func load() -> [StudySession] {   // ✅ public accessor
        sessions
    }

    private func save() {
        FileService.shared.save(sessions, to: fileName)
    }

    private func loadFromDisk() {     // ✅ renamed so no ambiguity
        sessions = FileService.shared.load([StudySession].self, from: fileName) ?? []
    }
}
