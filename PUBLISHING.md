# Publishing Lumina

Lumina is built on GitHub's cloud Macs (no Mac needed). Two workflows live in `.github/workflows`:

| Workflow | When it runs | What it does |
|---|---|---|
| **Build** | Every push to `main` | Builds the iPhone app, widgets, Apple Watch app and complication for the simulators. No Apple account needed. |
| **Release to TestFlight** | Started by hand from the Actions tab | Signs the app with your Apple account and uploads it to App Store Connect. |

## One-time setup

1. **GitHub**: a private repository named `lumina` holding this project.
2. **Apple Developer Program** (individual): note your **Team ID** at developer.apple.com → Account → Membership details.
3. **Agreements**: App Store Connect → Business → accept the **Paid Applications Agreement** and add banking and tax details. Subscriptions do not load until this is active.
4. **API key for the cloud Mac**: App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → **+**. Name it `GitHub`, role **Admin**, then download the `.p8` file (it can only be downloaded once). Add four repository secrets in GitHub → Settings → Secrets and variables → Actions:
   - `APPLE_TEAM_ID` — your Team ID
   - `ASC_KEY_ID` — the key's ID
   - `ASC_ISSUER_ID` — the Issuer ID shown above the key list
   - `ASC_PRIVATE_KEY` — open the `.p8` file in Notepad and paste its full text, including the BEGIN and END lines
5. **Register the app's IDs**: Actions → Release to TestFlight → Run workflow with **Upload** unticked. This creates Lumina's bundle IDs, App Group and HealthKit setting in your Apple account.
6. **Create the app record**: App Store Connect → Apps → **+** → New App. Platform iOS, name `Lumina: Daily Manifestation`, language English (U.S.), bundle ID `com.luminamanifestation.lumina`, SKU `lumina-001`, full access.
7. **In-app purchases** (Monetization):
   - Subscriptions → group `Lumina Premium` → `com.luminamanifestation.lumina.premium.yearly` ($44.99, 1 year) and `com.luminamanifestation.lumina.premium.monthly` ($6.99, 1 month). On each, add an Introductory Offer: Free, 1 week, all territories.
   - In-App Purchases → Non-Consumable → `com.luminamanifestation.lumina.premium.lifetime` ($99.99).
8. **Support site**: set `privacyURL` and `supportURL` in `Shared/AppConfig.swift` to the published pages.

## Each release

1. Raise `MARKETING_VERSION` in `project.yml` for a new public version (for example `1.0.1`). Build numbers are set automatically from the workflow run number.
2. Actions → Release to TestFlight → Run workflow (Upload ticked).
3. After 10–30 minutes the build appears in App Store Connect → TestFlight. Install it on your iPhone with the TestFlight app and test.
4. In the app's version page, choose the build, fill in the listing (see README), attach the three in-app purchases, and **Submit for Review**.

## If a signed build fails

The release log is saved as a workflow artifact. Common causes:
- *Agreement or license not accepted*: check the developer website and App Store Connect for a banner asking you to accept updated terms.
- *No devices*: register your iPhone at developer.apple.com → Devices with its UDID, then run the workflow again.
- *Bundle ID not found during upload*: the app record in step 6 hasn't been created yet.
