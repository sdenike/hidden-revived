# Changelog

All notable changes to Hidden Bar Revived are documented in this file.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Dates are shown in the developer's local time zone.

Hidden Bar Revived is a community-maintained continuation of the original [Hidden Bar](https://github.com/dwarvesf/hidden) by Dwarves Foundation. Versions prior to 2.0.0 were released by the original authors; see the [upstream repository](https://github.com/dwarvesf/hidden) for that history.

## [2.1.0] — 2026-04-28

### Changed
- **Minimum macOS raised to 13 (Ventura).** Apple's currently-supported macOS releases are 14 (Sonoma), 15 (Sequoia), and 26 (Tahoe); 13 ended security updates in September 2025 but remains a reasonable community-fork floor for Macs from 2017+. The previous 10.13 floor was supporting hardware nine years older than the current line.
- **Unified `MACOSX_DEPLOYMENT_TARGET = 13.0` across all targets** — main app, launcher helper, and tests. Previously the launcher target was on 10.14 while the main app was on 10.13.

### Removed
- Five `#available` checks (`macOS 10.14`, `10.15`, `11.0` ×2, `11.4`) that all became unconditional under the new floor — affecting `PreferencesViewController`, `AboutViewController`, `PreferencesWindowController`, and `NSView+Glass`.
- Legacy upstream icon assets `ico_compass`, `ico_twitter`, `ico_github`, `ico_email`, and `ico_fb` from `Assets.xcassets`. These were the macOS 10.13 fallback for the About screen's links; SF Symbols are now used unconditionally on the new floor.
- The corresponding `image=` references in `Main.storyboard` and the `<resources>` declarations.
- The `applySymbol` availability-gated helper in `AboutViewController`; SF Symbols load directly inline.

### Notes for next release
- Migration from `SMLoginItemSetEnabled` to `SMAppService.mainApp` and removal of the `LauncherApplication` helper target are deferred to 2.1.1 / 2.2.0 — both warrant a focused branch with login-flow testing.

## [2.0.6] — 2026-04-24

### Fixed
- **Constraint accumulation in the tutorial view.** Toggling "Enable always hidden section" used to add a new `centerXAnchor` constraint to the arrow image views on every rebuild without deactivating the previous one. Auto Layout would log unsatisfiable-constraint warnings and, over many toggles, could break the arrow alignment. Constraints are now stored on the view controller and deactivated before each rebuild.
- **Crash risk from missing tutorial assets.** `NSImage(named:)!` was force-unwrapped for every mock menu-bar icon in the Preferences tutorial; any rename in `Assets.xcassets` (notably the consistently-misspelled `seprated` / `seprated_1`) would crash on Preferences open. Replaced with a nil-safe lookup that falls back to a blank image and emits a debug assertion.
- "Always hidden section" help popover (the `?` next to the "Enable always hidden section" checkbox) no longer expands off-screen. The tutorial text now wraps at 340pt with proper padding, and the popover is positioned relative to the help button rather than the entire Preferences content view.
- Help popover typography — section headings ("Steps to enable:" / "Steps to view always hidden icons:") render as semibold secondary-label subtitles with extra leading space, and body paragraphs get comfortable line height.

### Changed
- **Preferences and About windows rebuilt for Liquid Glass.** Content area now carries an `NSVisualEffectView` backdrop (`.underWindowBackground` on macOS 11+, `.sidebar` fallback on 10.13) so the window's Glass titlebar flows through the content instead of butting against banded opaque backgrounds. Nested `NSBox` fills are cleared programmatically at view load rather than requiring storyboard surgery.
- **About screen links are now fork-first.** The upstream "Know more about us", "Follow us on Twitter", and "Email us" rows are replaced with **View on GitHub**, **Download latest release**, **Report an issue**, and **View MIT License** — all pointing at `github.com/sdenike/hidden-revived`. Icons switched to SF Symbols (`chevron.left.forwardslash.chevron.right`, `arrow.down.circle.fill`, `exclamationmark.bubble.fill`, `doc.text.fill`) on macOS 11 and later.
- Version label on the About screen uses monospaced digits (macOS 10.15+) for a cleaner build-stamp feel.
- "Settings" heading on the General tab reduced from 22pt systemBold / labelColor to 13pt systemBold / secondaryLabelColor, matching macOS HIG conventions for a group label inside a Preferences pane.

## [2.0.5] — 2026-04-23

### Fixed
- Preferences window titlebar is now a compact single row with the General/About pill fully contained. On macOS 26 Tahoe the previous toolbar style rendered taller than expected and the pill visually spilled below the titlebar.

## [2.0.4] — 2026-04-23

### Fixed
- General/About segmented control is now centered across the full width of the preferences window. Explicit `toolbarStyle = .preference` and `centeredItemIdentifiers` replace the earlier reliance on flexible-space items, which did not properly center past the traffic-light controls.

## [2.0.3] — 2026-04-23

### Fixed
- Initial attempt at centering the General/About segmented control via `centeredItemIdentifier`. Superseded by 2.0.4.

## [2.0.2] — 2026-04-23

### Fixed
- Preferences window no longer overlaps the macOS menu bar area. Removed `titlebarAppearsTransparent` and `fullSizeContentView` from the window style mask, which on modern macOS caused the tutorial's mock menu-bar imagery to bleed through the transparent titlebar behind the toolbar.
- Toolbar no longer shows `Custom View` fallback labels. Changed `displayMode` from `labelOnly` to `iconOnly`.

### Changed
- Repository references updated from `sdenike/hidden` to `sdenike/hidden-revived` in README and the About screen's source link.

## [2.0.1] — 2026-04-23

### Added
- About screen updated for the fork: title reads "Hidden Bar Revived", footer credits both Dwarves Foundation and the fork maintainer, source link points at the active fork. The Dwarves Foundation homepage, Twitter, and email links remain unchanged as original-author credits.
- `scripts/install.sh` — single-command build + install workflow for iterative testing. Builds Release with ad-hoc signing, gracefully quits any running instance (up to 10 s for `applicationWillTerminate` to complete), replaces `/Applications/Hidden Bar Revived.app`, and optionally launches.

## [2.0.0] — 2026-04-23

First release of the Hidden Bar Revived fork.

### Fixed
- **Ultra-wide and multi-monitor hiding.** Collapse length is now computed from the widest connected display rather than the focused one, and the cap was raised from 4,000 pt to macOS's actual 10,000 pt maximum. Collapsed state is also preserved across display connect/disconnect events. Adapted from upstream [PR #354](https://github.com/dwarvesf/hidden/pull/354) (laveez). Fixes upstream #314, #345, #353.
- **Runaway memory leak causing multi-GB usage on macOS Sequoia / Tahoe.** Addresses the 2.89 GB leak reported in upstream #326. Fix combines:
  - `NSLayoutConstraint.deactivate(view.constraints)` before `removeFromSuperview` in `NSStackView.removeAllSubViews` (primary leak source — constraints retained the removed `NSImageView` instances that the tutorial view recreated on every preference change).
  - `[weak self]` on `DispatchQueue.main.asyncAfter` closures in `StatusBarController` to prevent retain cycles.
  - `deinit` cleanup in `StatusBarController` and `PreferencesViewController` for `NotificationCenter` observers, and in `LauncherApplication.AppDelegate` for `DistributedNotificationCenter` observers.
  - Always-hidden `NSStatusItem` is now created once and reused instead of being destroyed and recreated on every toggle.
  - Timer invalidation and status item removal in `StatusBarController.deinit`.

  Adapted from upstream [PR #346](https://github.com/dwarvesf/hidden/pull/346) (Rob Mulder) and [PR #335](https://github.com/dwarvesf/hidden/pull/335) (huynguyenh).
- Debug `print(keyCode)` statement that leaked user hotkey data to the system console was removed.

### Added
- Italian localization ([upstream #196](https://github.com/dwarvesf/hidden/pull/196), Gian Marco Cinalli).
- Ukrainian localization ([upstream #226](https://github.com/dwarvesf/hidden/pull/226), GGorAA).
- Turkish localization ([upstream #320](https://github.com/dwarvesf/hidden/pull/320), Mete Kılıç).

### Changed
- Application renamed to **Hidden Bar Revived**.
- Main app bundle identifier changed to `com.sdenike.hiddenbar` (was `com.dwarvesv.minimalbar`).
- Launcher helper bundle identifier changed to `com.sdenike.hiddenbar.launcher` (was `com.dwarvesv.LauncherApplication`).
- Minimum macOS deployment target raised from 10.12 to **10.13** (High Sierra). Required by the current Xcode toolchain and the `HotKey` dependency. A further raise to macOS 13 is planned when the app migrates to `SMAppService` for launch at login.
- Copyright line now reads `© 2019 Dwarves Foundation · © 2026 Shelby DeNike`; the original MIT license and attribution are preserved.
