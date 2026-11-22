//
//  FiltersSheet.swift
//  Brewies
//

import SwiftUI

struct FiltersSheet: View {
    @Bindable var model: ExploreViewModel
    @Environment(\.dismiss) private var dismiss

    private var usesMetric: Bool { Locale.current.measurementSystem != .us }

    private var radiusOptions: [Double] {
        usesMetric ? [1_000, 3_000, 5_000, 10_000] : [1_609, 4_828, 8_047, 16_093]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Search distance") {
                    Picker("Distance", selection: $model.filters.radiusMeters) {
                        ForEach(radiusOptions, id: \.self) { meters in
                            Text(meters.formattedDistance).tag(meters)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Independent shops only", isOn: $model.filters.independentOnly)
                    Toggle("Hide places I've visited", isOn: $model.hideVisited)
                } footer: {
                    Text("Independent only hides well-known chains so local spots come first.")
                }
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
