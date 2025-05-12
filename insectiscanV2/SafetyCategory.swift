//
//  SafetyCategory.swift
//  insectiscanV2
//
//  Created by Jason Grife on 5/4/25.
//


// SafetyCategory.swift

import SwiftUI

enum SafetyCategory: String, CaseIterable, Identifiable {
    case wildlife = "Wildlife"
    case terrain = "Terrain"
    case weather = "Weather"
    case plants = "Plants"
    case insects = "Insects"
    case hydration = "Hydration"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wildlife: return "pawprint.fill"
        case .terrain: return "mountain.2.fill"
        case .weather: return "cloud.sun.rain.fill"
        case .plants: return "leaf.fill"
        case .insects: return "ant.fill"
        case .hydration: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .wildlife: return Color.green
        case .terrain: return Color.brown
        case .weather: return Color.blue
        case .plants: return Color.teal
        case .insects: return Color.orange
        case .hydration: return Color.cyan
        }
    }
}
