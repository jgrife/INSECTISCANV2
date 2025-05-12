//
//  Secrets.swift
//  insectiscanV2
//
//  Created by Jason Grife on 5/9/25.
//
import Foundation

enum Secrets {
    static var openAIKey: String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = plist["OPENAI_KEY"] as? String
        else {
            fatalError("❌ Missing OPENAI_KEY in Secrets.plist")
        }
        return key
    }
}

