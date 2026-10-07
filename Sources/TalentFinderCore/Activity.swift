import Foundation

/// Something a person could do — a job, a sport, a hobby — and which aptitudes it draws on.
public struct Activity: Identifiable, Hashable, Sendable {
    public enum Category: String, CaseIterable, Sendable {
        case work = "Work & Study"
        case creative = "Creative"
        case sport = "Sport & Movement"
        case hobby = "Hobbies"
    }

    public let name: String
    public let category: Category
    public let weights: [Aptitude: Double]

    public var id: String { name }
}

public enum ActivityCatalog {
    public static let all: [Activity] = [
        // Work & Study
        .init(name: "Software engineering", category: .work, weights: [.analytical: 0.8, .creative: 0.3, .handsOn: 0.2]),
        .init(name: "Data science", category: .work, weights: [.analytical: 1, .verbal: 0.2]),
        .init(name: "Architecture", category: .work, weights: [.spatial: 1, .creative: 0.6, .analytical: 0.3]),
        .init(name: "Teaching", category: .work, weights: [.social: 0.8, .verbal: 0.7, .leadership: 0.4]),
        .init(name: "Nursing & healthcare", category: .work, weights: [.social: 1, .analytical: 0.3, .physical: 0.3]),
        .init(name: "Journalism", category: .work, weights: [.verbal: 1, .social: 0.4, .analytical: 0.3]),
        .init(name: "Law", category: .work, weights: [.verbal: 0.9, .analytical: 0.7, .leadership: 0.5]),
        .init(name: "Starting a business", category: .work, weights: [.leadership: 1, .creative: 0.5, .social: 0.4]),
        .init(name: "Sales", category: .work, weights: [.leadership: 0.8, .social: 0.8, .verbal: 0.4]),
        .init(name: "Counselling & coaching", category: .work, weights: [.social: 1, .verbal: 0.5]),
        .init(name: "Engineering", category: .work, weights: [.handsOn: 0.8, .analytical: 0.8, .spatial: 0.4]),
        .init(name: "Carpentry", category: .work, weights: [.handsOn: 1, .spatial: 0.6]),
        .init(name: "Veterinary care", category: .work, weights: [.nature: 1, .analytical: 0.4, .social: 0.3]),
        .init(name: "Landscape design", category: .work, weights: [.nature: 0.7, .spatial: 0.7, .creative: 0.5]),
        .init(name: "Graphic design", category: .work, weights: [.creative: 0.9, .spatial: 0.8]),
        .init(name: "Event planning", category: .work, weights: [.leadership: 0.8, .social: 0.6, .creative: 0.3]),
        .init(name: "Translation", category: .work, weights: [.verbal: 1, .analytical: 0.2]),
        .init(name: "Scientific research", category: .work, weights: [.analytical: 0.9, .verbal: 0.3, .nature: 0.3]),
        .init(name: "Flying (pilot)", category: .work, weights: [.spatial: 0.8, .analytical: 0.5, .physical: 0.4]),
        .init(name: "Cooking professionally", category: .work, weights: [.creative: 0.6, .handsOn: 0.6, .physical: 0.4]),

        // Creative
        .init(name: "Painting & drawing", category: .creative, weights: [.creative: 1, .spatial: 0.7]),
        .init(name: "Creative writing", category: .creative, weights: [.verbal: 1, .creative: 0.9]),
        .init(name: "Playing an instrument", category: .creative, weights: [.musical: 1, .physical: 0.3]),
        .init(name: "Singing", category: .creative, weights: [.musical: 1, .social: 0.2]),
        .init(name: "Songwriting", category: .creative, weights: [.musical: 0.8, .creative: 0.7, .verbal: 0.6]),
        .init(name: "Photography", category: .creative, weights: [.spatial: 0.8, .creative: 0.7, .nature: 0.3]),
        .init(name: "Acting", category: .creative, weights: [.verbal: 0.6, .social: 0.5, .creative: 0.5, .physical: 0.4]),
        .init(name: "Film-making", category: .creative, weights: [.creative: 0.8, .spatial: 0.5, .leadership: 0.5]),

        // Sport & Movement
        .init(name: "Dance", category: .sport, weights: [.physical: 1, .musical: 0.7, .creative: 0.3]),
        .init(name: "Team sports", category: .sport, weights: [.physical: 1, .social: 0.4, .leadership: 0.3]),
        .init(name: "Martial arts", category: .sport, weights: [.physical: 1, .spatial: 0.2]),
        .init(name: "Rock climbing", category: .sport, weights: [.physical: 0.9, .spatial: 0.5, .nature: 0.3]),
        .init(name: "Running & endurance sports", category: .sport, weights: [.physical: 1, .nature: 0.3]),
        .init(name: "Yoga", category: .sport, weights: [.physical: 0.8, .nature: 0.2]),
        .init(name: "Sailing", category: .sport, weights: [.nature: 0.7, .physical: 0.6, .handsOn: 0.4]),

        // Hobbies
        .init(name: "Chess & strategy games", category: .hobby, weights: [.analytical: 1, .spatial: 0.5]),
        .init(name: "Puzzles & escape rooms", category: .hobby, weights: [.analytical: 0.9, .spatial: 0.4]),
        .init(name: "Gardening", category: .hobby, weights: [.nature: 1, .handsOn: 0.5]),
        .init(name: "Birdwatching", category: .hobby, weights: [.nature: 1, .spatial: 0.3]),
        .init(name: "Hiking", category: .hobby, weights: [.nature: 0.9, .physical: 0.7]),
        .init(name: "DIY & home repair", category: .hobby, weights: [.handsOn: 1, .spatial: 0.4]),
        .init(name: "Electronics & robotics", category: .hobby, weights: [.handsOn: 0.8, .analytical: 0.8]),
        .init(name: "Debating", category: .hobby, weights: [.verbal: 0.9, .analytical: 0.6, .leadership: 0.6]),
        .init(name: "Volunteering", category: .hobby, weights: [.social: 1, .leadership: 0.3]),
        .init(name: "Community organising", category: .hobby, weights: [.leadership: 0.9, .social: 0.7]),
        .init(name: "Learning languages", category: .hobby, weights: [.verbal: 1, .musical: 0.2]),
        .init(name: "Model making", category: .hobby, weights: [.handsOn: 0.8, .spatial: 0.7, .creative: 0.3]),
    ]
}
