//
//  MultipleSelectionList.swift
//  Brewies
//
//  Created by Noah Boyers on 7/24/23.
//

import SwiftUI

struct MultipleSelectionList: View {
    var title: String
    var items: [String]
    @Binding var selection: [String]
    
    var body: some View {
        ForEach(items, id: \.self) { item in
            Toggle(item, isOn: Binding(
                get: { self.selection.contains(item) },
                set: { if $0 { self.selection.append(item) } else { self.selection.removeAll { $0 == item } } }
            ))
        }
    }
}
