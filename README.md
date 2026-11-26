# Brewies

Brewies is an iOS app for finding independent coffee shops and breweries near you, and keeping a personal passport of the ones you've visited.

It is built around one idea: finding a shop is easy, but a record of *your* coffee life is something only your own app can give you.

## Features

- **Explore.** A map pinned at the top and a list of the closest independent shops below it. As you scroll, the shop at the top of the list is highlighted on the map, with the route and the walking or driving time from where you are. Chains are filtered out by default. Switch between coffee shops and breweries.
- **Passport.** Log a visit with a rating, what you ordered, notes and a photo. Browse the journal by month, filter by your own rating, see saved shops, and view a map of everywhere you've been.
- **Streaks.** Consecutive weeks at a favorite shop, with a one-tap check-in, a regular tier (Newcomer, Regular, Local, Fixture), a shareable streak card, and an optional weekly reminder when a streak is about to lapse.
- **Share.** Send a shop to a friend with an Apple Maps link.
- **Brewies Pro** (subscription). iCloud sync and backup, Insights (top-rated shops, usual orders, monthly trend), and CSV export. Logging visits is always free and unlimited.

## Requirements

- Xcode with the current iOS SDK
- iOS 18 or later (Liquid Glass styling is used on iOS 26 and later, with a material fallback before that)

## Getting started

1. Open `Brewies.xcodeproj` in Xcode and run the **Brewies** scheme on a simulator.
2. There are **no API keys to configure**. Place search, routing and photos all use Apple frameworks.
3. In the simulator, set a location with *Features > Location* (or `xcrun simctl location booted set 45.5231,-122.6765`) so nearby shops load.

Useful for development:

| What | How |
| --- | --- |
| Sample journal for screenshots and for checking streaks | Launch a **debug** build with the argument `-seedDemoData`. It replaces the journal with sample visits. |
| Test the subscription | Run from Xcode. The scheme uses `Brewies/Brewies.storekit`, so purchases are simulated. |
| Reset a test purchase | Xcode: *Debug > StoreKit > Manage Transactions*. |

## Project layout

```
Brewies/
  BrewiesApp.swift        App entry: data container, store, location
  Model/                  Shop, Visit, SavedShop, StreakEngine, IndependentShopFilter
  Services/               PlaceSearchService, TravelStore, LocationService, ShopImageStore,
                          StoreManager, DataStore, JournalExport, StreakReminders, DebugSeed
  ViewModels/             ExploreViewModel
  Views/                  Explore, Shop, Passport, Settings, Pro, Components
  Design/                 Theme and category artwork
docs/                     Architecture, Pro setup, and research notes
```

## Documentation

- [Architecture and design decisions](docs/ARCHITECTURE.md)
- [Setting up Pro, iCloud sync and the App Store](docs/PRO_AND_SYNC_SETUP.md)
- [Research: ordering through delivery platforms](docs/ORDERING_RESEARCH.md)

## Status

Brewies is in active development. Logic such as the streak calculation has been checked against known cases, and the main flows have been walked through on a simulator, but there is no automated test suite yet. iCloud sync has not been verified between two real devices.

## Roadmap

- Home-screen widget showing a shop from your Want to Try list or your streak
- Pin clustering on the map
- Measure demand for ordering ahead before building anything that handles payments

## Contributing

Brewies is open source and contributions are welcome. If you have an idea or found a bug, open an issue at [github.com/nboyers/Brewies/issues](https://github.com/nboyers/Brewies/issues). To contribute code, fork the repository and open a pull request.

## License

Brewies is released under the MIT license. See [LICENSE](https://choosealicense.com/licenses/mit/) for more information.
