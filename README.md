# BrickScan

A SwiftUI iOS app to scan LEGO® sets, manage your Rebrickable collection, and
look up what a set is worth across lego.com, BrickLink and Amazon.

> Personal hobby project, open-sourced under the [MIT license](LICENSE).
> Not affiliated with or endorsed by the LEGO Group, Rebrickable, BrickLink or
> Amazon. "LEGO" is a trademark of the LEGO Group.

## Features

- **Scan sets** — point the camera at a box barcode or type a set number to
  identify a LEGO set.
- **Collection sync** — link your Rebrickable account to see whether a set is
  already in your collection and in which list, and add/remove it.
- **Pricing** — for any set, see prices side by side:
  - the official **lego.com** price,
  - **BrickLink** 6-month sold average, new and used (complete sets only),
  - **Amazon** (genuine listings, accessories filtered out),
  - with a discount/markup percentage versus the lego.com price.
- **History** of scanned sets, with on-disk image caching for offline browsing.

## Requirements

- Xcode 16+ (Swift 6, strict concurrency)
- iOS 17.0+ (iPhone, portrait)
- [XcodeGen](https://github.com/yonyz/XcodeGen) — `brew install xcodegen`

## Building

The Xcode project is generated from [`project.yml`](project.yml) by XcodeGen —
**don't edit `BrickScan.xcodeproj` or `Info.plist` by hand**, they're
regenerated. Edit `project.yml` instead.

```bash
xcodegen generate
open BrickScan.xcodeproj
```

Before building, set your own signing identity — the committed
`DEVELOPMENT_TEAM` in `project.yml` is the original author's and won't work for
you. Either change it to your Apple Developer Team ID or clear it and let Xcode
manage signing automatically.

### Rebrickable API key

The app needs a free [Rebrickable](https://rebrickable.com) API key, entered
in-app under **Paramètres** (Settings) and stored in the Keychain — nothing is
hardcoded or committed. Generate one at
[rebrickable.com/profile](https://rebrickable.com/profile) under "API Key".
Linking your account (optional, for collection sync) uses your credentials once
to obtain a session token; the password is never stored.

## How pricing works

lego.com, BrickLink and Amazon all sit behind Cloudflare-style JS challenges
that a plain HTTP client can't pass, so prices are read by loading each page in
a hidden `WKWebView` (a real WebKit engine) and extracting the values from the
rendered DOM. Each source loads on its own web view so they run in parallel,
sharing one process pool/cookie store so the challenge clearance persists.
Results are cached locally; any source that fails is simply omitted.

## Project layout

- `BrickScan/App` — app entry point and root scene.
- `BrickScan/Core` — networking, repositories, scrapers, storage (SwiftData,
  Keychain, image cache).
- `BrickScan/Features` — one folder per screen (Scanner, Home, Collection,
  History, SetDetail, Settings, …).
- `AGENTS.md` — architecture notes and conventions.

## Contributing

Issues and pull requests are welcome. Please run `xcodegen generate` and make
sure the app builds (`** BUILD SUCCEEDED **`) before opening a PR — there is no
test target.

## License

[MIT](LICENSE) © Lunik
