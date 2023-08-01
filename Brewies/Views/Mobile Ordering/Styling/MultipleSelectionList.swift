//
//  MultipleSelectionList.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import SwiftUI

// Stub for MultipleSelectionList
struct MultipleSelectionList: View {
    var title: String
    var items: [String]
    @Binding var selection: [String]
    
    var body: some View {
        List(items, id: \.self) { item in
            Toggle(item, isOn: Binding(
                get: {
                    self.selection.contains(item)
                },
                set: { (newValue) in
                    if newValue {
                        self.selection.append(item)
                    } else {
                        self.selection.removeAll(where: { $0 == item })
                    }
                }
            ))
        }
    }
}
