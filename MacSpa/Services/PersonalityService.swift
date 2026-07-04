// PersonalityService.swift
import Foundation

enum QuipCategory {
    case keyboard, trackpad, display, completion
}

@MainActor
final class PersonalityService {
    static let shared = PersonalityService()
    private var recentIndices: [QuipCategory: [Int]] = [:]
    private let maxRecent = 3

    private let quips: [QuipCategory: [String]] = [
        .keyboard: [
            "That tickles.",
            "I can finally breathe between the keys.",
            "The Space bar appreciates the attention.",
            "You've pressed me 42,000 times this month. I deserved this.",
            "Those fingerprints were becoming permanent residents.",
            "Ahhh. That's the spot.",
            "The crumbs have been evicted.",
        ],
        .trackpad: [
            "That's the spot.",
            "Smoother already.",
            "Your future swipes thank you.",
            "I haven't felt this clean since unboxing day.",
            "Like new. Actually better.",
        ],
        .display: [
            "I can see clearly now.",
            "Goodbye fingerprints.",
            "Those pixels are looking sharp today.",
            "That's premium microfiber technique.",
            "The smudges have left the building.",
        ],
        .completion: [
            "Spa session complete.",
            "I feel brand new.",
            "Fresh, clean, and ready for work.",
            "Your Mac thanks you.",
            "That was deeply satisfying.",
        ],
    ]

    func quip(for category: QuipCategory) -> String {
        let pool = quips[category] ?? []
        guard !pool.isEmpty else { return "" }
        var recent = recentIndices[category] ?? []
        let available = pool.indices.filter { !recent.contains($0) }
        let idx = (available.isEmpty ? pool.indices.randomElement() : available.randomElement()) ?? 0
        recent.append(idx)
        if recent.count > maxRecent { recent.removeFirst() }
        recentIndices[category] = recent
        return pool[idx]
    }
}
