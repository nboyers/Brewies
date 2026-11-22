# Setting up Pro, iCloud sync and the App Store

The code for Brewies Pro is complete, but a few things only you can do, in Apple's systems. Nothing here is automated.

## 1. Subscription products (App Store Connect)

Create one **subscription group** (for example "Brewies Pro") with these exact product IDs. They are defined in `StoreManager.productIDs`.

| Product ID | Plan | Placeholder price in the test config |
| --- | --- | --- |
| `com.nobosoftware.brewies.pro.yearly` | Yearly, with a 1-week free trial | $19.99 |
| `com.nobosoftware.brewies.pro.monthly` | Monthly | $2.99 |

The prices and the trial in `Brewies/Brewies.storekit` are placeholders for local testing. Set the real ones in App Store Connect.

Also needed before submitting:

- an accepted **Paid Applications** agreement
- a privacy policy URL and terms of use URL (the paywall links to `nobosoftware.com/privacy` and Apple's standard EULA)
- App Privacy answers updated: the app no longer collects advertising data or tracks users

## 2. Testing purchases locally

Run the **Brewies** scheme from Xcode. The scheme uses `Brewies/Brewies.storekit`, so the purchase sheet is simulated and nothing is charged.

To go back to the free tier: *Debug > StoreKit > Manage Transactions*, then delete the transaction.

## 3. iCloud sync (CloudKit)

The entitlements file already contains iCloud with CloudKit, the container `iCloud.com.nobosoftware.Brewies`, and push notifications. `Info.plist` contains the `remote-notification` background mode CloudKit sync needs.

Do this once in Xcode:

1. Select the **Brewies** target, open **Signing & Capabilities**.
2. Confirm **iCloud** (with CloudKit and the container above), **Push Notifications** and **Background Modes** (Remote notifications) are listed.
3. If signing complains that the provisioning profile doesn't include the container, let Xcode's automatic signing register it, or create the container at developer.apple.com.

### Deploy the CloudKit schema before release

This step is easy to miss. During development, SwiftData creates the CloudKit schema in the **Development** environment. TestFlight and App Store builds use **Production**, which starts empty. Until you deploy, sync appears to work in development and silently does nothing for real users.

1. Open the [CloudKit Dashboard](https://icloud.developer.apple.com).
2. Choose the container, then **Deploy Schema Changes** to Production.
3. Redeploy whenever the `Visit` or `SavedShop` models gain properties.

### Verifying sync

The simulator has no iCloud account, so sync has not been verified here. To check it:

1. Sign two devices into the same Apple ID.
2. Start a Pro subscription on one (sandbox or TestFlight).
3. Log a visit on the first and confirm it appears on the second.

## 4. What happens when the subscription lapses

`StoreManager` re-reads entitlements at launch and on every transaction update. When Pro ends, the app opens a local-only store again. The user's data stays on the device. Sync, Insights and export are locked until they resubscribe.

## 5. Changing what Pro includes

Gating is done in three places, all checking `StoreManager.isPro`:

- `PassportView` (the Insights tab and the backup reminder)
- `SettingsView` (the Pro card and the export row)
- `BrewiesApp` and `DataStore` (whether sync is on)

Update the paywall copy in `PaywallView.marketing` to match.
