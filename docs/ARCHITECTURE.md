# Architecture

Brewies is a SwiftUI app with no backend. Everything runs on the device, and iCloud sync (a Pro feature) moves the user's own data between their devices.

## Layers

| Layer | Responsibility | Key types |
| --- | --- | --- |
| Model | Plain values and the persisted data | `Shop`, `Visit`, `SavedShop`, `StreakEngine` |
| Services | Anything that talks to the system or the network | `PlaceSearchService`, `TravelStore`, `LocationService`, `ShopImageStore`, `StoreManager`, `DataStore` |
| View models | Screen state that outlives a view | `ExploreViewModel` |
| Views | SwiftUI screens, grouped by feature | `ExploreView`, `ShopDetailView`, `PassportView`, `StreaksView` |
| Design | Colors, type, surfaces, category artwork | `Theme`, `CategoryIcon` |

State uses the Observation framework (`@Observable`) and SwiftData. There is no Combine.

## Where data comes from

**Places** come from Apple MapKit (`MKLocalPointsOfInterestRequest` plus a text query, merged and de-duplicated). Results are limited to the chosen radius, filtered to the right category, and, by default, to independent shops.

**Photos** are Look Around snapshots (`MKLookAroundSnapshotter`), cached in memory. Where Apple has no Look Around imagery, the row falls back to branded artwork.

**Travel time** comes from `TravelStore`. It shows a quick distance-based estimate immediately (marked `~`), then replaces it with a real MapKit route for the shop the user has paused on. Trips over about 20 minutes on foot are shown as a drive.

**Independent filter.** `IndependentShopFilter` matches a curated list of chain names as whole-word sequences, so a local shop named "Noble Coffee" is not caught by "Barnes & Noble".

## Why MapKit and not Google Places

Brewies originally used the Google Places API. It was replaced for these reasons:

- Google's terms do not allow Places content on a non-Google map, and the app drew results on an Apple map.
- Google restricts caching Places content other than the place ID. A passport has to store shop names and locations permanently.
- Google bills per request, so costs grow with usage while subscription revenue stays small.
- MapKit needs no API key, no proxy backend and no per-request cost.

The trade-off is that Apple's data has **no public star ratings, photos or opening hours**. The rating filter and rating display use the user's own ratings. If public ratings become important, the options are Google's SDK with a Google map, or a community rating layer.

## Persistence

`Visit` and `SavedShop` are SwiftData models. They are written to stay **CloudKit compatible**, which is what lets sync be switched on later without migrating:

- every property has a default value or is optional
- no unique constraints
- any relationships must be optional

`DataStore.makeContainer(sync:)` builds the container. Free users get a local-only store. Pro users get a CloudKit-backed store using `iCloud.com.nobosoftware.Brewies`. If the CloudKit store can't open (for example, no iCloud account), it falls back to a local store so the app always launches. `BrewiesApp` swaps the container when the subscription starts or lapses.

`StoreManager` caches the last verified entitlement in `UserDefaults` so the right database opens at launch even when offline.

## Streaks

A streak is the number of **consecutive calendar weeks** with at least one visit. `StreakEngine` is a pure function over value types, so it does not depend on SwiftData.

- A streak stays alive until the current week ends. With no visit yet this week it counts back from last week and is marked *at risk*.
- Weeks follow the user's calendar, so a Monday-first locale and a Sunday-first locale split weeks differently.
- The journal streak counts a visit to any shop. Per-shop streaks count visits to that shop only.
- `RegularTier` is Newcomer, Regular (3 visits), Local (8), Fixture (20).

`StreakReminders` schedules at most one local notification a week, about a day and a half before the week ends, for a streak of two or more weeks that has not yet been visited this week.

## Free versus Pro

| Free | Pro |
| --- | --- |
| Search, shop details, sharing, saved shops | iCloud sync and backup |
| Unlimited visits, photos, ratings, journal, map | Insights |
| Streaks, check-in, share card, reminders | CSV export |

Logging is deliberately never capped. The journal is what keeps people in the app, so Pro sells safety, insight and portability rather than access.

## Lessons worth remembering

- **Don't use `safeAreaInset` to host content over a SwiftUI `Map`.** Changing the inset when results load made the camera collapse to a minimal span. Overlay the content, or keep the map in its own fixed-size container.
- **Don't start a map at `.userLocation(fallback:)` if you also set the camera yourself.** The two fight. Use `.automatic` and set a region on the first location fix.
- **`Info.plist` must be tracked.** The project points at `Brewies/Info.plist`, and it carries the background mode that CloudKit sync needs. `.gitignore` excludes other plists but explicitly keeps this one.
- **Avoid deprecated MapKit placemark APIs on newer systems.** `Shop.swift` and `TravelStore.swift` branch on `#available(iOS 26, *)` to use `MKMapItem.location` and `address` there.
