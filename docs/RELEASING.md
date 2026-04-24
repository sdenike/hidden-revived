# Releasing Hidden Bar Revived

This runbook covers cutting a signed + notarized release and updating the
Homebrew tap. One-time setup is at the bottom.

## Every release

1. **Bump the version** in `Hidden Bar.xcodeproj/project.pbxproj`
   (`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`) and add a section to
   `CHANGELOG.md`. Commit to `main`.
2. **Tag and push:**
   ```bash
   git tag v2.0.x
   git push origin v2.0.x
   ```
   The `Release` GitHub Actions workflow picks up the tag, builds, signs,
   notarizes, staples, and publishes `HiddenBarRevived-2.0.x.zip` to the
   GitHub release.
3. **Grab the sha256** from the workflow run's summary (section "Cask
   values"), or compute it locally from the downloaded asset:
   ```bash
   shasum -a 256 HiddenBarRevived-2.0.x.zip
   ```
4. **Update the Homebrew tap** — edit `Casks/hidden-revived.rb` in
   `github.com/sdenike/homebrew-hidden-revived`:
   ```ruby
   version "2.0.x"
   sha256 "<new-sha256>"
   ```
   Commit, push to `main`. Users on `brew upgrade --cask hidden-revived`
   will pick it up on their next run.

## Local-only signing (without GitHub Actions)

Run the same pipeline that CI runs, from your own machine:

```bash
./scripts/release.sh
```

Outputs `dist/HiddenBarRevived-<version>.zip` and a sibling `.sha256`. Pass
`SKIP_NOTARIZE=1` to skip Apple notarization (for smoke-testing the signing
chain locally); pass `DRY_RUN=1` to skip notarization AND stapling.

## One-time setup

### Developer ID certificate

1. Generate a CSR in Keychain Access → Certificate Assistant → Request a
   Certificate From a Certificate Authority.
2. Upload the CSR at
   https://developer.apple.com/account/resources/certificates and download
   the resulting `Developer ID Application` cert.
3. Double-click to install in login keychain.
4. Verify:
   ```bash
   security find-identity -v -p codesigning
   ```
   You should see:
   ```
   "Developer ID Application: Shelby Denike (485WH9DHS4)"
   ```
5. **Back up the certificate + private key** as a `.p12` — select both
   rows in Keychain Access → right-click → Export 2 items. Stash the file
   in a password manager.

### notarytool keychain profile (for local `release.sh`)

```bash
xcrun notarytool store-credentials "HiddenBarNotary" \
    --apple-id   "you@example.com" \
    --team-id    "485WH9DHS4" \
    --password   "xxxx-xxxx-xxxx-xxxx"
```

The password is an app-specific password generated at
https://appleid.apple.com → Sign-In and Security → App-Specific Passwords.

### GitHub Actions secrets (for the `Release` workflow)

Add these to
`github.com/sdenike/hidden-revived/settings/secrets/actions`:

| Secret | Value |
|---|---|
| `MACOS_CERTIFICATE` | `base64 -i DeveloperID.p12 \| pbcopy` then paste |
| `MACOS_CERTIFICATE_PASSWORD` | The password protecting the `.p12` |
| `KEYCHAIN_PASSWORD` | Any throwaway string (a fresh keychain is created each run) |
| `APPLE_ID` | Apple ID email tied to the developer account |
| `APPLE_TEAM_ID` | `485WH9DHS4` |
| `APPLE_APP_PASSWORD` | App-specific password (same one used locally) |

Once the secrets exist, any `v*` tag pushed to `main` runs the full signed
release flow automatically.
