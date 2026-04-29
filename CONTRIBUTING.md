# Contributing

Hidden Bar Revived is a community-maintained fork of [Hidden Bar](https://github.com/dwarvesf/hidden). The project's goal is to keep the app working and modern, not to add major new features. Focused bug fixes, OS-compatibility patches, and small UX refinements are very welcome.

## Filing an issue

Use [GitHub Issues](https://github.com/sdenike/hidden-revived/issues) for bug reports, regressions, and feature questions. Please include:

- macOS version and Mac model
- Hidden Bar Revived version (visible in **About** inside Preferences)
- Reproduction steps
- A screenshot, screen recording, or `Console.app` log snippet if relevant

For privacy or security-related concerns, please use [GitHub's private security advisory flow](https://github.com/sdenike/hidden-revived/security/advisories/new) rather than a public issue.

## Pull requests

1. Open an issue first if the change is non-trivial (more than a small bug fix or a typo). It avoids wasted work on either side.
2. Fork, branch, build locally with `./scripts/install.sh`, and verify the change in a real Preferences window before pushing.
3. Match the existing code style — there's no formal linter, but the codebase is small and consistent. Keep the diff focused.
4. Update `CHANGELOG.md` if your change is user-visible.
5. Open the PR against `main`.

### Branch naming

The repo uses short, single-word-prefixed branch names that describe the kind of work:

- `fix/...` — bug fix
- `chore/...` — refactor, cleanup, infrastructure
- `feat/...` — small feature work
- `docs/...` — README / CHANGELOG / docs only

Example: `fix/preferences-glass-refresh`, `chore/macos-13-deployment-target`.

### Merging

Maintainers merge with `--no-ff` so each PR's history is preserved as a discrete merge commit on `main`. Tags follow `v<version>` (e.g. `v2.1.0`); pushing a tag triggers the [`Release`](.github/workflows/release.yml) workflow which produces the signed + notarized artifact for distribution.

## Code of Conduct

This project follows the [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to abide by its terms. Enforcement concerns can be raised privately via [GitHub's security advisory flow](https://github.com/sdenike/hidden-revived/security/advisories/new).
