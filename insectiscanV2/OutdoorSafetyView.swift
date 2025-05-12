// OutdoorSafetyView.swift
// insectiscanV2

import SwiftUI

struct SafetyTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let tips: [String]
    let link: URL?
}

let safetyTopics: [SafetyTopic] = [
    SafetyTopic(
        icon: "pawprint.fill",
        title: "Wildlife Encounters",
        tips: [
            "What to do if you encounter a bear, cougar, or snake: Stay calm, back away slowly without turning your back. Don’t run. Make yourself look large and make noise. Carry bear spray where applicable.",
            "How to keep food safe from raccoons, bears, or rodents: Store food in bear-proof containers or hang it at least 10 feet off the ground and 4 feet away from tree trunks. Never store food inside your tent."
        ],
        link: URL(string: "https://www.nps.gov/subjects/watchingwildlife/safety.htm")
    ),
    SafetyTopic(
        icon: "cloud.bolt.rain.fill",
        title: "Weather Safety",
        tips: [
            "What to do if a thunderstorm approaches on a hike: Seek shelter below the treeline, away from isolated trees, ridges, or metal.",
            "How to stay safe in high heat or sudden cold: Hydrate, wear light clothing, or layer for warmth. Avoid cotton and stay dry."
        ],
        link: URL(string: "https://www.weather.gov/safety/")
    ),
    SafetyTopic(
        icon: "map.fill",
        title: "Navigation & Survival",
        tips: [
            "How to use sun, stars, or natural features to find direction: Sun rises in the east and sets in the west. Use Polaris to find north.",
            "Emergency shelter advice using natural materials: Use branches, leaves, or tarps to build a lean-to or debris hut."
        ],
        link: URL(string: "https://www.rei.com/learn/expert-advice/navigation-basics.html")
    ),
    SafetyTopic(
        icon: "flame.fill",
        title: "Fire & Water",
        tips: [
            "Safe ways to purify water: Boil for 1 minute, or use filters/tablets.",
            "How to safely start and extinguish a campfire: Clear a ring, keep small, douse with water, stir ashes."
        ],
        link: URL(string: "https://smokeybear.com/en/prevention-how-tos/campfire-safety")
    ),
    SafetyTopic(
        icon: "figure.walk",
        title: "Trail & Terrain Safety",
        tips: [
            "How to avoid getting lost on a trail: Use maps, GPS, and landmarks. Let someone know your route.",
            "What to do if injured far from help: Stabilize injury, signal for help."
        ],
        link: URL(string: "https://americanhiking.org/resources/hiking-safety/")
    ),
    SafetyTopic(
        icon: "tent",
        title: "Campsite Safety",
        tips: [
            "Where to set up a safe campsite: Flat, dry ground away from hazards.",
            "How to avoid attracting animals: Don’t store food or scented items in your tent."
        ],
        link: URL(string: "https://lnt.org/why/7-principles/")
    ),
    SafetyTopic(
        icon: "ant.fill",
        title: "Insects & Plants",
        tips: [
            "How to identify and avoid poisonous plants: Learn to recognize poison ivy/oak.",
            "How to treat a bug bite or sting outdoors: Clean, elevate, use antihistamines."
        ],
        link: URL(string: "https://www.cdc.gov/ticks/avoid/on_people.html")
    ),
    SafetyTopic(
        icon: "drop.fill",
        title: "Hydration & Health",
        tips: [
            "How much water to bring: 1 liter per 2 hours.",
            "Recognize dehydration: Dizziness, dark urine. Sip water slowly."
        ],
        link: URL(string: "https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/water/art-20044256")
    ),
    SafetyTopic(
        icon: "snowflake",
        title: "Cold Weather & Altitude",
        tips: [
            "How to dress for cold hikes: Layer with moisture-wicking and insulating clothes.",
            "Recognize altitude sickness: Nausea, dizziness. Rest and descend if necessary."
        ],
        link: URL(string: "https://www.rei.com/learn/expert-advice/cold-weather-hiking.html")
    )
]

struct OutdoorSafetyView: View {
    @State private var expandedTopic: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Outdoor Safety Guide")
                    .font(.largeTitle.bold())
                    .padding(.top)
                    .foregroundColor(Color("PrimaryColor"))

                ForEach(safetyTopics) { topic in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedTopic == topic.id },
                            set: { expandedTopic = $0 ? topic.id : nil }),
                        content: {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(topic.tips, id: \ .self) { tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(Color("AccentColor"))
                                        Text(tip)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .transition(.opacity)
                                            .animation(.easeInOut(duration: 0.3), value: tip)
                                    }
                                }

                                if let link = topic.link {
                                    Link("Learn more", destination: link)
                                        .font(.footnote)
                                        .foregroundColor(.blue)
                                        .padding(.top, 6)
                                }
                            }
                            .padding(.top, 6)
                        },
                        label: {
                            HStack(spacing: 12) {
                                Image(systemName: topic.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color("PrimaryColor"))
                                    .clipShape(Circle())

                                Text(topic.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    )
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
    }
}
