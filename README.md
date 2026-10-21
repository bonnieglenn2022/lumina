# Lumina — Daily Manifestation (iPhone + Apple Watch)

A calm, premium manifestation app in SwiftUI, designed around what the top wellness apps (Calm, Headspace, I am, Finch, Duolingo's habit system) do best.

**Look and feel**
- Warm cream background with moonlit blue, plus a deep-navy **Evening mode** (automatic from 7 PM to 5 AM, or choose Day, Evening, or System)
- Affirmations set in Apple's elegant serif (New York), with SF Pro Rounded for everything else
- 12 **card themes** (4 free) used on Today, the home-screen widget, and share cards
- Custom **notification chime** and a soft **completion tone** (`iOS/Resources`)

**Daily practice**
- **Today**: one manifestation, "I receive this" check-in, today's intention, and a gentle "Welcome back" message instead of guilt when a streak lapses
- **Streaks with freezes**: a freeze quietly protects a missed day (2 max free, 3 Premium); earn one at each milestone
- **Milestone celebrations** only at 7, 30, 100, and 365 days, with a shareable card for Instagram or Messages
- **Mood check-in**: one tap after checking in
- **Breathe & repeat** (4s in, 6s out) by day, **Wind down** by night, with soundscapes: Rain, Ocean, Wind, Brown noise
- **Record in your own voice** (Premium) and play it back from the card
- **Library** of 70 original manifestations in 7 categories, plus **Mine** for writing your own

**Everywhere**
- **iPhone widgets**: Home Screen (small and medium, themed) and Lock Screen (affirmation, inline, streak), with an in-app guide for adding them
- **Apple Watch**: Today, Breathe & repeat with haptics, favorites, and a watch-face complication
- **Apple Health** (optional): Mindful Minutes from breathing sessions and State of Mind from mood check-ins (iOS 18+)
- **Reminders** with the "I receive this ✨" action on iPhone and Watch

**Premium**: monthly or yearly with a 7-day free trial, or a one-time lifetime purchase. Includes a day-5 trial reminder, Restore Purchases, and all required disclosures.

| | Free | Premium |
|---|---|---|
| Categories | Gratitude, Confidence | All 7 |
| Card themes | 4 | All 12 |
| Soundscapes | Rain, Brown noise | All |
| Daily reminders | 1 | Up to 6 |
| Personal manifestations | 3 | Unlimited |
| Record in your own voice | — | ✓ |
| Streak freezes (max) | 2 | 3 |
| Widgets, Watch app, Apple Health, mood, wind-down | ✓ | ✓ |

**Pricing:** $6.99/month or $44.99/year (both with a 7-day free trial), or $99.99 lifetime. This still undercuts I am ($59.99/year) and Calm (about $70/year).

---|---|---|
| Categories | Gratitude, Confidence | All 7 |
| Daily reminders | 1 | Up to 6 |
| Personal manifestations | 3 | Unlimited |
| Apple Watch app + complication | ✓ | ✓ |
| Streaks, favorites, intention | ✓ | ✓ |

Suggested pricing: **$4.99/month** or **$29.99/year**, both with a 7-day free trial.

---

## 1. What you need

- A Mac with **Xcode 15.3 or newer** (free from the Mac App Store)
- An **Apple Developer Program** membership ($99/year) — developer.apple.com/programs
- Optional: an iPhone and Apple Watch for real-device testing

## 2. Open the project (about 5 minutes)

1. Unzip `Lumina.zip` somewhere on your Mac (e.g. Documents).
2. Open **Terminal**, then:
   ```bash
   cd ~/Documents/Lumina
   chmod +x setup.sh
   ./setup.sh com.yourbusinessname ABCDE12345
   ```
   - `com.yourbusinessname` — any reverse-domain prefix you control (e.g. `com.texaslightworks`). It becomes your bundle ID, App Group and product IDs.
   - `ABCDE12345` — your Team ID from developer.apple.com → Account → Membership details.
   - The script installs XcodeGen (via Homebrew) if needed, generates `Lumina.xcodeproj` and opens it.
3. In Xcode, select the **Lumina** scheme and an iPhone simulator, then press **⌘R**.

**Testing purchases:** the scheme already uses `Lumina.storekit`, so the paywall shows real-looking prices and you can start the free trial in the simulator without App Store Connect. In Xcode use **Debug → StoreKit → Manage Transactions** to expire or refund and test both states.

**Testing the Watch:** choose the **LuminaWatch** scheme with a paired iPhone + Watch simulator pair.

> If Xcode warns about signing, open the project → each target → *Signing & Capabilities* → pick your Team. Xcode registers the App Group automatically.

## 3. Before you publish — edit `Shared/AppConfig.swift`

- `privacyURL` — host `privacy-policy.html` (included) on your website and paste the link
- `supportURL` — your published Help & Support page
- `termsURL` — Apple's standard EULA is already set; fine to keep

## 4. App Store Connect setup

1. **Create the app:** appstoreconnect.apple.com → Apps → **+** → New App. Platform iOS, name (e.g. *Lumina: Daily Manifestation* — check availability; if taken try *Lumina Manifest* or rename `CFBundleDisplayName` in `project.yml`), bundle ID from step 2, SKU `lumina-001`.
2. **Agreements:** Business → sign the **Paid Applications Agreement** and add banking + tax info. *Subscriptions won't load until this is active.*
3. **Subscriptions:** your app → Monetization → **Subscriptions** → create group *Lumina Premium*, then two subscriptions:

   | Reference name | Product ID | Duration | Price |
   |---|---|---|---|
   | Premium Yearly | `com.yourbusinessname.lumina.premium.yearly` | 1 year | $44.99 |
   | Premium Monthly | `com.yourbusinessname.lumina.premium.monthly` | 1 month | $6.99 |

   Then add the lifetime option under Monetization → **In-App Purchases** → **+** → **Non-Consumable**: Product ID `com.yourbusinessname.lumina.premium.lifetime`, price $99.99.

   For each subscription: add a display name/description, then **Introductory Offers → Create → Free → 1 week** for all territories. Add a review screenshot of the paywall. Put Yearly at a higher level than Monthly in the group (level 1).
4. **App Privacy:** answer **"Data Not Collected."** Mood, voice recordings, and Health entries stay on the device and in the user's own Apple Health; nothing is sent to you.
   **HealthKit:** in App Review notes, explain that Lumina writes Mindful Minutes and State of Mind only when the user turns it on in Settings, and never reads Health data.
5. **Age rating:** 4+. **Category:** Health & Fitness (secondary: Lifestyle).

## 5. Ship it

1. In Xcode: set the run destination to **Any iOS Device**, then **Product → Archive**.
2. In the Organizer: **Distribute App → App Store Connect → Upload**.
3. In App Store Connect add screenshots (6.9" iPhone and Apple Watch), the listing text below, attach both subscriptions to the version ("In-App Purchases and Subscriptions" section), then **Submit for Review**. First reviews typically take 1–3 days.

**Screenshots tip:** run in the iPhone 16 Pro Max simulator and press ⌘S on Today, Library, Mine, the paywall, and onboarding step 2. For Watch, run the Watch simulator (Series 10, 46mm) and ⌘S the Today page and a watch face with the complication.

### Common review notes (pre-empted in this build)
- Paywall shows price, period, trial length, auto-renew terms, Restore, Terms & Privacy links, and can be closed ✔
- App is useful without paying (free tier) ✔
- Notifications are requested with context, not on first launch ✔
- Privacy manifest included (`PrivacyInfo.xcprivacy`) ✔
- In *App Review Information → Notes* write: "Premium is an auto-renewable subscription with a 7-day free trial. All content is bundled; no login required."

## 6. App Store listing copy (ready to paste)

**Subtitle (30):** Daily affirmations & intention

**Promotional text (170):** Start each day with a manifestation chosen for you — on your iPhone and your Apple Watch. Try Premium free for 7 days.

**Description:**
> Lumina is a calm, beautiful space for your daily manifestation practice.
>
> Each day you receive one manifestation chosen from the areas you want to grow — gratitude, confidence, abundance, love, health, career, or peace. Read it, breathe, and tap "I receive this" to make it yours. Gentle reminders arrive at the times you choose, on your iPhone and your Apple Watch.
>
> FEATURES
> • A new manifestation every day, matched to what you want to manifest
> • Gentle daily reminders with a one-tap "I receive this"
> • Apple Watch app with a guided Breathe & Repeat and a watch-face complication
> • Write your own manifestations in your own words
> • Daily streaks and a space to set today's intention
> • Favorites you can share
> • Private by design — no account, nothing leaves your device
>
> LUMINA PREMIUM
> Unlock all 7 categories, up to 6 daily reminders, and unlimited personal manifestations. Try it free for 7 days, then choose monthly or yearly. Payment is charged to your Apple ID at the end of the trial. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple ID account settings.
>
> Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
> Privacy Policy: [your privacy URL]

**Keywords (100):** affirmations,manifest,law of attraction,gratitude,mindset,intention,positive,journal,abundance,calm

## Adding real nature recordings (optional)
Soundscapes are generated live by default, so they work immediately. For recorded nature audio, add royalty-free or licensed loops named `rain.m4a`, `ocean.m4a`, `wind.m4a`, or `brown.m4a` to the `iOS/Resources` folder. Lumina plays a recording automatically when one is present. Check each file's license before shipping.

## Adding photo themes (optional)
Add an image to `iOS/Assets.xcassets`, then give a theme in `Shared/Theme.swift` an `imageName:` value (e.g. `imageName: "forest-photo"`).

## Project structure

```
Lumina/
├─ project.yml            XcodeGen spec (3 targets)
├─ setup.sh               one-step setup
├─ Shared/                used by iPhone, Watch and complication
│  ├─ AppConfig.swift     ← IDs, URLs, free/premium limits
│  ├─ AffirmationLibrary.swift  70 manifestations + daily picker
│  ├─ Affirmation.swift, WatchSnapshot.swift, Theme.swift
├─ iOS/
│  ├─ App/LuminaApp.swift
│  ├─ Services/  AppState, StoreManager, NotificationManager, PhoneSessionManager
│  ├─ Views/     Onboarding, Today, Library, Mine, Settings, Paywall, Components
│  ├─ Lumina.storekit, PrivacyInfo.xcprivacy, Assets.xcassets
├─ Watch/                 watchOS app (Today, Breathe & repeat, Favorites)
├─ iOSWidget/             iPhone Home Screen + Lock Screen widgets
└─ WatchWidget/           watch-face complication
```

### Easy customizations
- **Add/edit manifestations:** `Shared/AffirmationLibrary.swift`
- **Which categories are free:** `isFree` in `Shared/Affirmation.swift`
- **Limits:** `Shared/AppConfig.swift`
- **Colors & fonts:** `Shared/Theme.swift`

### Troubleshooting
- *"No such module" / build errors after editing project.yml* → re-run `xcodegen generate`.
- *Watch app not installing with the iPhone app* → Lumina target → Build Phases → confirm an "Embed" phase copies `LuminaWatch.app` to `$(CONTENTS_FOLDER_PATH)/Watch`.
- *Paywall says "Loading plans…" on a device* → the Paid Applications Agreement isn't active yet, or product IDs don't match `AppConfig.swift`.
