# Labfire Publication & Refactor Open Tasks

Goal: finish turning the fork/redesign into a clean, maintainable, legally publishable open repository. Do not add personal hosts, IP addresses, domains, SSH keys, credentials, or bootstrap passwords to this file.

## Publication readiness

- Verify all CI-equivalent checks from a fresh clone.
- Complete third-party notices/licenses for every bundled non-original asset family.
- Confirm all image/font/icon assets are original, clearly licensed, or replaced.
- Run a history-aware secret scan before publishing.

## Asset cleanup and licensing

### Complete third-party asset notices

- Finish provenance review for upstream bundled sound/image/screenshot/browser assets.
- Confirm Flaticon Uicons license/attribution requirements for the bundled subset.
- Decide whether to continue loading Inter from Google Fonts or bundle a local licensed font.
- Update `THIRD_PARTY_NOTICES.md` with any missing ownership/license details.

Acceptance check:

- Every non-original asset family has a notice entry.
- README continues to link to `THIRD_PARTY_NOTICES.md`.

## Branding and configuration cleanup

### Finish centralizing public app identity

Brand configuration exists in `config/initializers/brand.rb`; continue replacing scattered hardcoded public strings where practical.

Remaining candidates:

- Web share filename prefix.
- Help contact/version labels.
- Account invite text.
- PWA/system-setting instructional references.
- Any remaining public-facing fallback strings that should come from brand config.

Acceptance check:

- Hardcoded brand-name strings only remain where intentional, documented, or required for compatibility.

## UI architecture refactor

### Split `zz_gammalabs.css`

`app/assets/stylesheets/zz_gammalabs.css` is still a large monolithic redesign layer.

- Split it into smaller files loaded after upstream styles, for example:
  - `brand_tokens.css`
  - `brand_base.css`
  - `brand_app_shell.css`
  - `brand_sidebar.css`
  - `brand_topbar.css`
  - `brand_messages.css`
  - `brand_composer.css`
  - `brand_account_settings.css`
  - `brand_forms.css`
  - `brand_mobile.css`
- Preserve load order so visual output does not regress.
- Remove local absolute path comments from CSS headers.
- Track counts before/after:
  - `rg -n "!important" app/assets/stylesheets`
  - `rg -n ":has" app/assets/stylesheets`
  - duplicated selector audit.

Acceptance check:

- Visual smoke test covers sign-in, chat room, sidebar, profile, account settings, new DM, new room, search, and lightbox.

### Decide long-term icon delivery

`IconsHelper` now centralizes icon markup, but the app still uses the Uicons webfont.

- Decide whether to keep the Uicons webfont or switch to inline SVG sprites.
- If keeping the font:
  - Move `uicons-regular-rounded.woff2` to an appropriate font asset location or document why it remains under images.
  - Confirm `font-display` and CSP are acceptable.
- If switching to SVG:
  - Add an SVG sprite or helper-generated inline SVGs.
  - Remove `uicons-regular-rounded.woff2` and `_uicons.css`.

Acceptance check:

- Icons render before and after Turbo navigation.
- Every icon helper name maps to an available glyph/asset.

### Resolve translation feature state

`TranslationsHelper#translation_button` still returns `nil` while translation data remains.

Choose one:

1. Restore the translation button with redesigned icon/menu.
2. Remove translation data and all `translation_button(...)` calls.

If restoring:

- Replace old globe SVG with the icon helper.
- Add accessibility labels and keyboard support.

If removing:

- Delete unused translation hashes.
- Remove layout gaps caused by missing translation buttons.

Acceptance check:

- No method returns silent `nil` as a placeholder for unfinished UI.

## Rails/View correctness improvements

### Expand accessibility smoke coverage

Known icon-label issues were fixed; broaden test coverage for icon-only controls.

- Add or update system smoke tests that find icon-only controls by accessible name.
- Include account menu/theme controls, message actions, profile actions, and PWA controls.

Acceptance check:

- System tests cover representative icon-only controls by accessible name.

## CI, scans, and fresh-clone verification

### Reproduce GitHub CI from a clean state

- Clone the repo into a new directory.
- Run:
  - `bundle install`
  - `bin/rails db:setup test`
  - `bin/rails db:setup test:system`
  - `bin/rubocop`
  - `bin/brakeman`
  - Docker build with asset precompile.
- Investigate any clean-clone `db:setup` foreign-key failure and ensure CI remains reliable.

Acceptance check:

- Fresh clone passes without relying on existing local databases or assets.

### Secret scan before publishing

Run at least one:

```bash
gitleaks detect --source .
trufflehog git file://$PWD
```

Acceptance check:

- No secrets, private hostnames, private IPs, bootstrap credentials, or personal tokens in tracked history.
- If history contains sensitive data, rotate affected secrets and rewrite history before public release.

## Publication tasks

### Finish open-source metadata

Already added: `SECURITY.md`, `THIRD_PARTY_NOTICES.md`.

Remaining:

- Finalize the vulnerability reporting process/contact in `SECURITY.md`.
- Add `CODE_OF_CONDUCT.md` if desired.
- Add `CHANGELOG.md` or release notes for the fork delta.
- Review/add `.github/dependabot.yml` with correct package ecosystems and schedule.
- Ensure README links to any new metadata files.

### Prepare first public release

- Ensure GHCR workflow publishes under the intended public repository.
- Confirm package visibility will be public.
- Confirm Actions permissions are minimal and pinned actions remain pinned.
- Tag release only after CI is green, e.g. `v0.1.0`.
- Add release notes covering:
  - Fork attribution.
  - Major redesign changes.
  - Known limitations.
  - Upgrade caveats from Once Campfire.

Acceptance check:

- Public repo page renders README correctly.
- Public Docker image can be pulled and started by a third party.
