//
//  UIApplication+Extensions.swift
//  insectiscanV2
//
//  Created by Jason Grife on 5/9/25.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
