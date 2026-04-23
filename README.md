<p align="center">
	<img width="200" height="200" margin-right="100%" src="img/icon_512%402x.png">
</p>
<p align="center">
	<a href="https://github.com/sdenike/hidden/releases/latest">
 		<img src="https://img.shields.io/badge/download-latest-brightgreen.svg" alt="download">
	</a>
	<img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="platform">
	<img src="https://img.shields.io/badge/requirements-macOS%2010.13+-ff69b4.svg" alt="systemrequirements">
</p>

# Hidden Bar Revived

**Hidden Bar Revived** is a maintained continuation of the original [Hidden Bar](https://github.com/dwarvesf/hidden) by [Dwarves Foundation](https://github.com/dwarvesf), an ultra-light macOS utility that hides menu bar items to give your Mac a cleaner look.

The upstream project has been inactive for an extended period. This fork picks up where it left off — merging the most-requested community fixes, resolving the memory leak affecting macOS Sequoia/Tahoe, and keeping the app compatible with current macOS releases.

<p align="center">
	<img width="400" src="img/screen1.png">
	<img width="400" src="img/screen2.png">
</p>

## What's new in 2.0

- Fixes the runaway memory leak that was growing to several GB on macOS Sequoia and Tahoe
- Correctly hides menu bar items on ultrawide and multi-monitor setups
- Preserves collapsed state when displays are connected or disconnected
- Additional localizations: Italian, Ukrainian, Turkish
- Minimum macOS version raised to 10.13 (High Sierra) to match current Xcode requirements

## Install

### Homebrew (once we publish the cask)
```
brew install --cask hiddenbar-revived
```

### Manual download
- [Download the latest release](https://github.com/sdenike/hidden/releases/latest)
- Drag the app to your `Applications` folder
- Launch it and drag the icon in your menu bar (hold `⌘`) to the right so it sits between some other icons

### Mac App Store
Coming soon.

## Usage

- `⌘` + drag to move the Hidden Bar icons around in the menu bar
- Click the arrow icon to hide menu bar items

<p align="center">
	<img src="img/tutorial.gif">
</p>

## Requirements

- macOS 10.13 High Sierra or later

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Bug reports and focused PRs welcome — the goal of this fork is to keep Hidden Bar working, not to add major new features.

## Credits

- **Original authors:** Thanh Nguyen, Phuc Le Dien, and the [Dwarves Foundation](https://github.com/dwarvesf) team
- **Contributors:** See the full list on the [original repository](https://github.com/dwarvesf/hidden/graphs/contributors)
- **Maintainer of this fork:** [Shelby DeNike](https://github.com/sdenike)

## License

MIT — see [LICENSE](LICENSE). © 2019 Dwarves Foundation, © 2026 Shelby DeNike.
