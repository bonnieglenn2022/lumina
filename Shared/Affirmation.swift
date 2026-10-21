import Foundation

enum ManifestCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case gratitude, confidence, abundance, love, health, career, peace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gratitude: return "Gratitude"
        case .confidence: return "Confidence"
        case .abundance: return "Abundance"
        case .love: return "Love"
        case .health: return "Health"
        case .career: return "Career"
        case .peace: return "Peace"
        }
    }

    var subtitle: String {
        switch self {
        case .gratitude: return "Notice the good"
        case .confidence: return "Trust yourself"
        case .abundance: return "Wealth & opportunity"
        case .love: return "Relationships & self-love"
        case .health: return "Body & energy"
        case .career: return "Work & purpose"
        case .peace: return "Calm & clarity"
        }
    }

    var symbol: String {
        switch self {
        case .gratitude: return "hands.sparkles"
        case .confidence: return "figure.stand"
        case .abundance: return "leaf"
        case .love: return "heart"
        case .health: return "figure.mind.and.body"
        case .career: return "star"
        case .peace: return "moon.stars"
        }
    }

    /// Free users can use Gratitude and Confidence. Everything else is Premium.
    var isFree: Bool { self == .gratitude || self == .confidence }
}

struct Affirmation: Identifiable, Codable, Hashable {
    var id: String
    var text: String
    /// `nil` means the user wrote it themselves.
    var category: ManifestCategory?

    init(id: String = UUID().uuidString, text: String, category: ManifestCategory?) {
        self.id = id
        self.text = text
        self.category = category
    }

    var isCustom: Bool { category == nil }
    var categoryTitle: String { category?.title ?? "My Manifestation" }
    var categorySymbol: String { category?.symbol ?? "pencil.and.scribble" }
}
