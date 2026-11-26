//
//  DataStore.swift
//  Brewies
//
//  Builds the SwiftData container. iCloud sync is a Pro feature, so free users get a local-only store.
//

import SwiftData

enum DataStore {
    static let cloudContainerID = "iCloud.com.nobosoftware.Brewies"

    private static let schema = Schema([Visit.self, SavedShop.self])

    /// A container that syncs through iCloud when `sync` is true and iCloud is available,
    /// falling back to a local store so the app always opens.
    static func makeContainer(sync: Bool) -> ModelContainer {
        if sync {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudContainerID))
            if let container = try? ModelContainer(for: schema, configurations: cloud) {
                return container
            }
        }

        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: local) {
            return container
        }

        // The on-disk store couldn't be opened at all; keep the app usable for this session.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: memory)
        } catch {
            fatalError("Could not create a data store: \(error)")
        }
    }
}
