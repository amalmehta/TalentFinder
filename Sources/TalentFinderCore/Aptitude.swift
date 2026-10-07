import Foundation

/// One area of natural aptitude the survey measures.
public enum Aptitude: String, CaseIterable, Codable, Identifiable, Sendable {
    case analytical, verbal, spatial, musical, physical
    case social, leadership, creative, handsOn, nature

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .analytical: "Analytical"
        case .verbal: "Words & Language"
        case .spatial: "Spatial & Visual"
        case .musical: "Musical & Rhythmic"
        case .physical: "Physical & Movement"
        case .social: "People & Empathy"
        case .leadership: "Leading & Persuading"
        case .creative: "Creative & Imaginative"
        case .handsOn: "Hands-on & Mechanical"
        case .nature: "Nature & Living Things"
        }
    }

    public var symbol: String {
        switch self {
        case .analytical: "function"
        case .verbal: "text.quote"
        case .spatial: "cube"
        case .musical: "music.note"
        case .physical: "figure.run"
        case .social: "person.2"
        case .leadership: "megaphone"
        case .creative: "paintpalette"
        case .handsOn: "wrench.and.screwdriver"
        case .nature: "leaf"
        }
    }

    public var summary: String {
        switch self {
        case .analytical: "You enjoy spotting patterns, reasoning step by step and solving problems with logic and numbers."
        case .verbal: "Words come easily to you — reading, writing, explaining and playing with language."
        case .spatial: "You think in pictures: you can picture shapes, layouts and routes, and see how things fit together."
        case .musical: "You're tuned in to sound, pitch and rhythm, and music sticks with you."
        case .physical: "You learn through your body — coordination, balance, timing and movement feel natural."
        case .social: "You read people well, notice how others feel and help them feel understood."
        case .leadership: "You like to take charge, persuade others and get a group moving towards a goal."
        case .creative: "You generate original ideas and enjoy making things that didn't exist before."
        case .handsOn: "You like to build, fix and take things apart, and you understand how machines work."
        case .nature: "You're drawn to animals, plants and the outdoors, and notice details in the natural world."
        }
    }
}
