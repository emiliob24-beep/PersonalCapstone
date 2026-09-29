//
//  Color+Theme.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/4/26.
//

import SwiftUI
import UIKit

extension Color {
    static let appAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.64, blue: 0.87, alpha: 1.0)  // lighter blue for dark backgrounds
            : UIColor(red: 0.11, green: 0.29, blue: 0.51, alpha: 1.0) // deep navy for light backgrounds
    })
}
