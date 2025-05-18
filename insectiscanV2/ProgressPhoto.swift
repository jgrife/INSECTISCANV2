//
//  ProgressPhoto.swift
//  insectiscanV2
//
//  Created by Jason Grife on 5/17/25.
//


import Foundation

struct ProgressPhoto: Identifiable, Codable, Hashable {
    var id = UUID()
    var day: Int
    var imageURL: String
    var date: Date
}
