//
//  UIViewControllerKey.swift
//  Brewies
//
//  Created by Noah Boyers on 6/19/23.
//

import Foundation
import SwiftUI

struct UIViewControllerKey: EnvironmentKey {
    static var defaultValue: UIViewController? {
        UIApplication.shared.windows.first?.rootViewController
    }
}

extension EnvironmentValues {
    var rootViewController: UIViewController? {
        get { self[UIViewControllerKey.self] }
        set { self[UIViewControllerKey.self] = newValue }
    }
}
