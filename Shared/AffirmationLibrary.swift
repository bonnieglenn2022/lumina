import Foundation

/// Original manifestation content bundled with the app (works fully offline).
enum AffirmationLibrary {
    private static let source: [ManifestCategory: [String]] = [
        .gratitude: [
            "I am grateful for this day and everything it is bringing me.",
            "My life is full of quiet blessings, and I notice every one.",
            "I give thanks for the people who love and support me.",
            "Gratitude opens my heart and draws more goodness to me.",
            "I appreciate my body for carrying me through every day.",
            "I find something beautiful in every moment.",
            "I am thankful for how far I have already come.",
            "Every breath I take is a gift, and I receive it fully.",
            "I celebrate small joys as much as big ones.",
            "The more I give thanks, the more I have to be thankful for."
        ],
        .confidence: [
            "I trust myself to make good decisions.",
            "I am worthy of the space I take up.",
            "I speak with clarity, and I am heard.",
            "I believe in my abilities and my potential.",
            "I am becoming the most confident version of myself.",
            "My voice matters, and I share it freely.",
            "I meet challenges with courage and calm.",
            "I release the need for anyone's approval but my own.",
            "I am proud of who I am becoming.",
            "I walk into every room knowing I belong."
        ],
        .abundance: [
            "Money flows to me easily and often.",
            "I am open to receiving unexpected blessings.",
            "Abundance surrounds me in every form.",
            "I am a magnet for wonderful opportunities.",
            "I have more than enough, and I share generously.",
            "My income grows as I grow.",
            "I deserve to live a rich and beautiful life.",
            "Wealth and well-being come to me naturally.",
            "Every day I see new paths to prosperity.",
            "I welcome abundance with an open heart."
        ],
        .love: [
            "I am deeply loved, and I love deeply.",
            "I attract relationships that honor who I am.",
            "My heart is open to giving and receiving love.",
            "I am surrounded by people who lift me up.",
            "I treat myself with the kindness I give to others.",
            "Love flows through my life with ease.",
            "I communicate with patience and compassion.",
            "I am worthy of a love that feels safe and joyful.",
            "My relationships grow stronger every day.",
            "I radiate warmth, and it returns to me."
        ],
        .health: [
            "My body is strong, healthy, and full of energy.",
            "I nourish my body with what it truly needs.",
            "I feel vibrant and well in every part of me.",
            "I rest without guilt and wake renewed.",
            "I move my body with joy and gratitude.",
            "Healing energy flows through me with every breath.",
            "I listen to my body and honor its wisdom.",
            "I choose habits that support my well-being.",
            "I feel lighter, calmer, and more alive each day.",
            "I am at home in my body."
        ],
        .career: [
            "I do meaningful work that I am proud of.",
            "Success comes to me through focus and consistency.",
            "I am a valuable contributor wherever I go.",
            "New doors open for me at exactly the right time.",
            "I lead with confidence, integrity, and vision.",
            "My skills are recognized and rewarded.",
            "I turn ideas into action with ease.",
            "I am building something that lasts.",
            "I attract clients and partners who value my work.",
            "Every step I take moves me closer to my goals."
        ],
        .peace: [
            "I am calm, centered, and grounded.",
            "I release what I cannot control.",
            "Peace begins with my next breath.",
            "I let go of worry and welcome ease.",
            "My mind is quiet, and my heart is light.",
            "I move through my day with gentle steadiness.",
            "I forgive myself and others, and I feel free.",
            "I am safe in this moment.",
            "Stillness restores me.",
            "Everything is unfolding in my favor."
        ]
    ]

    static let all: [Affirmation] = ManifestCategory.allCases.flatMap { category in
        (source[category] ?? []).enumerated().map { index, text in
            Affirmation(id: "\(category.rawValue)-\(index)", text: text, category: category)
        }
    }

    static func items(in category: ManifestCategory) -> [Affirmation] {
        all.filter { $0.category == category }
    }
}

/// Deterministically picks "today's" manifestation so iPhone, notifications,
/// Apple Watch and the complication all show the same one.
enum DailyPicker {
    static func dayNumber(for date: Date, calendar: Calendar = .current) -> Int {
        calendar.ordinality(of: .day, in: .era, for: date) ?? 0
    }

    static func pool(categories: Set<ManifestCategory>, isPremium: Bool, custom: [Affirmation]) -> [Affirmation] {
        var allowed = isPremium ? categories : categories.filter { $0.isFree }
        if allowed.isEmpty { allowed = Set(ManifestCategory.allCases.filter { $0.isFree }) }
        let library = AffirmationLibrary.all.filter { item in
            guard let c = item.category else { return false }
            return allowed.contains(c)
        }
        return (library + custom).sorted { stableHash($0.id) < stableHash($1.id) }
    }

    static func affirmation(for date: Date, slot: Int = 0, pool: [Affirmation]) -> Affirmation {
        guard !pool.isEmpty else { return AffirmationLibrary.all[0] }
        let index = (dayNumber(for: date) + slot * 5) % pool.count
        return pool[(index + pool.count) % pool.count]
    }

    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in string.utf8 { hash = (hash &<< 5) &+ hash &+ UInt64(byte) }
        return hash
    }
}
