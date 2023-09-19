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
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first?.rootViewController
        }
        return nil
    }
}

extension EnvironmentValues {
    var rootViewController: UIViewController? {
        get { self[UIViewControllerKey.self] }
        set { self[UIViewControllerKey.self] = newValue }
    }
}
