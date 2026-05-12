# Labfire Publication & Refactor Implementation Plan

Goal: turn the current fork/redesign into a clean, maintainable, legally publishable open repository. This plan intentionally replaces the previous private deployment notes. Do not add personal hosts, IP addresses, domains, SSH keys, credentials, or bootstrap passwords back into this file.

## Definition of Done

The repo is ready to publish when all of these are true:

- Working tree is clean except for intentional committed changes.
- No personal/private deployment details are tracked.
- All CI-equivalent checks pass from a fresh clone.
- Brakeman and RuboCop are green.
- All image/font/icon assets are either original, clearly licensed, or replaced.
- README clearly identifies the project as a fork/derivative of Once Campfire and includes accurate setup/deploy instructions.
- Third-party notices/licenses are present for bundled fonts/icons/images.

## Phase 0 — Repository hygiene and safety

### 0.1 Remove private/local artifacts from git scope

- Delete or keep untracked and ignored:
  - `.claude/`
  - `Screenshot 2026-05-12 at 13.30.28.png`
  - any temporary local files under the repo root.
- Verify:
  - `git status --short` shows no local tool config, screenshots, temp logs, or private notes.
  - `rg -n "tail[0-9a-z]|100\.|Cloudflare|1Password|initial-admin|bootstrap|SSH key|password is|admin@|gammalabs\.cc|mini\." .` returns no publish-sensitive content outside tests/examples.

### 0.2 Convert real deployment config into a template

- Replace tracked `config/deploy.yml` with a generic `config/deploy.example.yml` or parameterized `config/deploy.yml` that contains placeholders only.
- Required placeholder fields:
  - `service: labfire`
  - `image: ghcr.io/YOUR_ORG/labfire`
  - `servers.web.hosts: [ YOUR_HOST ]`
  - `proxy.host: YOUR_DOMAIN`
  - `registry.username: <%= ENV.fetch("KAMAL_REGISTRY_USERNAME") %>`
- Move any real deploy file to an ignored local path, e.g. `config/deploy.local.yml` or `.kamal/deploy.yml`.
- Update `.gitignore` so real deploy configs and `.kamal/secrets*` remain ignored while examples stay tracked.
- Acceptance check:
  - `rg -n "tjansn|gammalabs|tail|mini|100\." config .kamal bin PLAN.md README.md` returns no private deployment values.

### 0.3 Make `bin/kamal` generic

- Remove the hardcoded personal 1Password SSH agent path.
- If agent selection is still desired, support it via `KAMAL_SSH_AUTH_SOCK`:
  - If `KAMAL_SSH_AUTH_SOCK` is set and points to a socket, export `SSH_AUTH_SOCK=$KAMAL_SSH_AUTH_SOCK`.
  - Otherwise leave `SSH_AUTH_SOCK` unchanged.
- Update comments to describe generic use.
- Acceptance check:
  - `rg -n "1Password|Group Containers|tom|2BUA8C4S2C" bin/kamal` returns nothing.

## Phase 1 — Fix release blockers

### 1.1 Fix non-preview attachment rendering crash

Problem: `Messages::AttachmentPresentation#render_link` calls `uicon(...)`, but `uicon` is not delegated to the view context.

Implementation:

- Edit `app/helpers/messages/attachment_presentation.rb`.
- Add `:uicon` to the delegate list:
  - `delegate :tag, :link_to, :broadcast_image_tag, :rails_blob_path, :url_for, :uicon, to: :context`
- Add/extend a controller or helper test that renders a message with a non-preview attachment and asserts no exception.
- Suggested fixture: upload a `.txt` file or another non-previewable blob.
- Acceptance check:
  - New test fails before the delegate fix and passes after.
  - `bin/test` passes.

### 1.2 Harden account logo serving and remove Brakeman warning

Problem: non-variable account logos are served inline from an ActiveStorage path with user-controlled content type.

Implementation options, in priority order:

1. Preferred: reject non-variable/non-raster uploads at validation time.
2. Acceptable: if an attached logo is not variable, ignore it and serve the stock placeholder instead.
3. Do not keep arbitrary inline `send_file` for uploaded content.

Specific tasks:

- Add server-side validation for `Account#logo`:
  - Allowed content types: `image/png`, `image/jpeg`, `image/webp`.
  - Reject SVG, HTML, XML, PDF, and any unknown type.
  - Add a reasonable byte-size limit.
- Add equivalent validation for `User#avatar` because avatars/bot avatars are also uploaded and processed.
- Update controllers to only serve processed variants for uploaded logos/avatars.
- Remove the `send_file ActiveStorage::Blob.service.path_for(Current.account.logo.key), content_type: Current.account.logo.content_type` fallback from `Accounts::LogosController`.
- Add tests:
  - Valid JPEG logo returns PNG variant.
  - SVG/HTML logo upload is rejected.
  - Non-variable attached logo does not render inline.
  - Valid avatar still returns WebP.
- Acceptance check:
  - `bin/brakeman -q` has no file access warning for `Accounts::LogosController`.

### 1.3 Fix RuboCop offenses

Current known offense:

- `app/controllers/users/sidebars_controller.rb:19`
- RuboCop wants spaces inside the array literal.

Implementation:

- Change:
  - `limit([DIRECT_PLACEHOLDERS - exclude_user_ids.count, 0].max)`
- To:
  - `limit([ DIRECT_PLACEHOLDERS - exclude_user_ids.count, 0 ].max)`
- Acceptance check:
  - `bin/rubocop` passes.

### 1.4 Remove obsolete Brakeman ignore entry

- Run Brakeman after fixing logo serving.
- Remove the obsolete ignore fingerprint from `config/brakeman.ignore`.
- Acceptance check:
  - `bin/brakeman -q` exits 0.
  - Brakeman report contains no obsolete ignore entries.

## Phase 2 — Asset cleanup and licensing

### 2.1 Replace inherited Campfire app icon

Problem: `app/assets/images/labfire-icon.png` is currently identical to the deleted `campfire-icon.png`.

Implementation:

- Replace `app/assets/images/labfire-icon.png` with an original Labfire icon or remove the footer logo entirely.
- If keeping a new icon:
  - Provide source file if available.
  - Optimize PNG dimensions and file size.
  - Update alt text in `app/views/layouts/application.html.erb` if visual identity changes.
- Acceptance check:
  - `cmp -s <(git show upstream/main:app/assets/images/campfire-icon.png) app/assets/images/labfire-icon.png` must not report identical files.

### 2.2 Decide and document Robby placeholder assets

Current untracked assets:

- `app/assets/images/robby.jpg`
- `app/assets/images/logos/robby-192.png`
- `app/assets/images/logos/robby-512.png`

Implementation:

- Decide whether Robby is allowed in the open repo.
- If yes:
  - Add license/ownership note in `THIRD_PARTY_NOTICES.md` or `NOTICE.md`.
  - Strip metadata/EXIF from `robby.jpg`.
  - Optimize all Robby assets.
- If no:
  - Replace with an original generated placeholder.
- Acceptance check:
  - `exiftool app/assets/images/robby.jpg` or equivalent shows no private metadata.
  - Notices file identifies ownership/license.

### 2.3 Restore or remove deleted SVG references

Known broken references:

- `app/assets/stylesheets/avatars.css` references `cancel.svg`.
- `app/assets/stylesheets/composer.css` references `common-file-text.svg`.
- `app/assets/stylesheets/composer.css` also references `remove-circle.svg`, which still exists.

Implementation:

- Either restore the referenced SVGs or replace these CSS backgrounds with existing assets/Uicons-compatible CSS.
- For banned avatar overlay, prefer CSS-only icon/text-free treatment or an existing safe asset.
- For composer common-file thumbnail, use a retained file icon asset or CSS-only placeholder.
- Add an asset reference audit script or test if practical.
- Acceptance check:
  - A script scanning `image_tag`, `broadcast_image_tag`, and CSS `url(...)` reports no missing assets, ignoring dynamic paths like `browsers/#{browser}.svg`.

### 2.4 Fix incorrect PWA asset path

Problem: `app/views/pwa/_install_instructions.html.erb` references `install-edge.svg`, but the tracked file is `external/install-edge.svg`.

Implementation:

- Change `image_tag "install-edge.svg"` to `image_tag "external/install-edge.svg"`.
- Acceptance check:
  - Render install instructions for Edge without missing asset errors.

### 2.5 Third-party asset notices

Create `THIRD_PARTY_NOTICES.md` with entries for:

- Original Once Campfire / 37signals MIT license and copyright.
- Flaticon Uicons font subset:
  - Source URL.
  - License terms.
  - Whether attribution is required.
- Google/Inter font usage, or remove Google-hosted font and bundle a licensed local font.
- Robby/logo/image assets, if kept.
- Any upstream sound/image assets that remain bundled.

Acceptance check:

- Every non-original asset family has an entry.
- README links to `THIRD_PARTY_NOTICES.md`.

## Phase 3 — Branding and configuration cleanup

### 3.1 Centralize public app identity

Implementation:

- Add a small initializer, e.g. `config/initializers/brand.rb`, with values such as:
  - `config.x.brand.name`
  - `config.x.brand.repository_url`
  - `config.x.brand.support_email`
  - `config.x.brand.description`
- Replace scattered hardcoded public strings where practical:
  - `ApplicationHelper#page_title_tag`
  - push notification test title
  - PWA manifest fallback name/description
  - web share filename prefix
  - help contact/version labels
  - account invite text
- Keep compatibility strings only where required by existing data/protocols, e.g. `application/vnd.campfire.mention`.
- Acceptance check:
  - `rg -n "Labfire|labfire|gammalabs|tjansn" app config README.md` only shows expected brand config, docs, tests, or compatibility references.

### 3.2 Update web push VAPID subject

Problem: `lib/web_push/notification.rb` still uses `mailto:support@37signals.com`.

Implementation:

- Replace with configured support email from brand config or `ENV.fetch("VAPID_SUBJECT", ...)`.
- Document `VAPID_SUBJECT` in README if using an environment variable.
- Add a unit test for VAPID subject construction if practical.
- Acceptance check:
  - `rg -n "support@37signals.com" app lib config` returns nothing.

### 3.3 Complete README for open publication

Implementation:

- Add a clear opening paragraph:
  - Labfire is a fork/derivative of Basecamp/37signals Once Campfire.
  - It is not affiliated with or endorsed by 37signals unless that is explicitly true.
- Add sections:
  - Features.
  - Local development.
  - Docker deployment.
  - Kamal deployment using the example config.
  - Upgrade path from upstream.
  - Security reporting.
  - License and third-party notices.
- Fix environment variable typo:
  - README currently documents `SSL_DOMAIN` but example uses `TLS_DOMAIN`; verify actual runtime variable and make both docs and example correct.
- Acceptance check:
  - A new user can follow README from a fresh clone.

### 3.4 Update issue/discussion links for a generic fork

Implementation:

- If publishing under a known repo, update `.github/ISSUE_TEMPLATE/config.yml` and README links to that repo.
- If not final yet, avoid hardcoded personal repo links and use placeholders only in docs.
- Acceptance check:
  - `rg -n "tjansn" .github README.md CONTRIBUTING.md` only appears if intentionally publishing under that account.

## Phase 4 — UI architecture refactor

### 4.1 Split `zz_gammalabs.css`

Problem: `app/assets/stylesheets/zz_gammalabs.css` is ~4,483 lines with repeated selectors and many `!important` overrides.

Implementation:

- Replace the monolithic file with smaller files loaded after upstream styles, for example:
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
- Acceptance check:
  - Visual smoke test covers sign-in, chat room, sidebar, profile, account settings, new DM, new room, search, lightbox.

### 4.2 Create a dedicated icon helper

Current issue: `uicon` lives in `ApplicationHelper`, always sets `aria-hidden`, and some calls pass `alt` or label-like ARIA to an `<i>` element.

Implementation:

- Move icon logic to `app/helpers/icons_helper.rb`.
- Provide API:
  - `icon(name, size: 20, decorative: true, label: nil, **options)`
  - Decorative icons set `aria-hidden="true"`.
  - Non-decorative icons set `role="img"` and `aria-label`.
- Remove invalid `alt:` usage on icon elements.
- Update all `uicon` calls or keep `uicon` as a compatibility wrapper temporarily.
- Add tests for decorative and labelled icon output.
- Acceptance check:
  - `rg -n "uicon .*alt:|aria: \{ hidden:.*label" app/views app/helpers` returns nothing.

### 4.3 Revisit icon font choice

Implementation:

- Decide whether to keep the Uicons webfont or switch to inline SVG sprites.
- If keeping font:
  - Move `uicons-regular-rounded.woff2` to an appropriate font asset location or document why it remains under images.
  - Confirm `font-display` and CSP are acceptable.
- If switching to SVG:
  - Add an SVG sprite or helper-generated inline SVGs.
  - Remove `uicons-regular-rounded.woff2` and `_uicons.css`.
- Acceptance check:
  - Icons render before and after Turbo navigation.
  - No missing glyphs: every icon helper name maps to an available glyph/asset.

### 4.4 Restore a maintainable avatar strategy

Current behavior trends toward using one Robby image for all missing avatars, while initials SVG rendering remains in the codebase.

Implementation:

- Decide product behavior:
  - Recommended: user avatars default to initials; bot avatars default to a bot/robot image; account logo defaults to a generic brand mark.
- If initials are restored:
  - Update `Users::AvatarsController` to render initials for normal users without uploaded avatar.
  - Keep bot-specific placeholder only for bots.
  - Remove `robby1` cache-busting suffix from `routes.rb` unless still needed.
- Add tests:
  - Normal user without avatar returns SVG initials.
  - Bot without avatar returns bot placeholder.
  - Uploaded avatar returns WebP.
- Acceptance check:
  - No dead avatar rendering paths remain.

### 4.5 Clean translation feature removal or restoration

Current state: `TranslationsHelper#translation_button` returns `nil`, but translation data remains.

Implementation:

- Choose one:
  1. Restore translation button with redesigned icon/menu.
  2. Remove translation data and all `translation_button(...)` calls.
- If removing:
  - Delete unused translation hashes.
  - Remove layout gaps caused by missing translation buttons.
- If restoring:
  - Replace old globe SVG with icon helper.
  - Add accessibility labels and keyboard support.
- Acceptance check:
  - No method returns silent `nil` as a placeholder for unfinished UI.

## Phase 5 — Rails/View correctness improvements

### 5.1 Use Rails Turbo frame helper

Implementation:

- Replace direct header checks:
  - `request.headers["Turbo-Frame"] == "direct_rooms_control"`
  - `request.headers["Turbo-Frame"] == "shared_rooms_control"`
- Prefer `turbo_frame_request?` plus `turbo_frame_request_id` if available, or wrap this logic in a helper method.
- Acceptance check:
  - Sidebar inline new-DM and new-room tests still pass.

### 5.2 Fix duplicate boost accessibility IDs

Problem: `messages/boosts/_boost.html.erb` emits `id="delete_boost_accessible_label"` for each boost.

Implementation:

- Use a per-boost ID:
  - `label_id = dom_id(boost, :delete_accessible_label)`
  - set `aria-describedby: label_id`
  - set `<span id="<%= label_id %>">...`
- Update `boost_delete_controller.js` so it does not hardcode `delete_boost_accessible_label`.
- Acceptance check:
  - A page with multiple boosts has no duplicate IDs.

### 5.3 Fix flash markup

Problem: `app/views/layouts/application.html.erb` has stray `</span>` after flash icons.

Implementation:

- Remove the extra closing `</span>` after both alert/check icons.
- Add a layout rendering assertion if practical.
- Acceptance check:
  - HTML validator or rendered response shows balanced markup.

### 5.4 Audit `aria-hidden` and labels around icons/images

Implementation:

- Review all changed views for:
  - `aria-hidden="true"` combined with meaningful labels.
  - icon-only buttons missing accessible names.
  - decorative images with non-empty alt text.
- Specific known candidates:
  - `app/views/users/show.html.erb` message button icon.
  - PWA instruction icons using icon helper with `alt:`.
  - account menu/theme toggle labels.
- Acceptance check:
  - System smoke tests can find icon-only controls by accessible name.

## Phase 6 — CI, scans, and fresh-clone verification

### 6.1 Run full local checks

Run:

```bash
bin/test
bin/rubocop
bin/brakeman -q
```

If local Ruby requires Nix or another wrapper, document that in README or improve binstubs so these commands work consistently.

Acceptance check:

- All commands exit 0.

### 6.2 Reproduce GitHub CI from a clean state

Implementation:

- Clone the repo into a new directory.
- Run:
  - `bundle install`
  - `bin/rails db:setup test`
  - `bin/rails db:setup test:system`
  - `bin/rubocop`
  - `bin/brakeman`
  - Docker build with asset precompile.
- Investigate current `db:setup` foreign-key failure seen in a dirty local DB and ensure CI remains reliable from a clean clone.
- Acceptance check:
  - Fresh clone passes without relying on existing local databases or assets.

### 6.3 Secret scan before publishing

Run at least one:

```bash
gitleaks detect --source .
trufflehog git file://$PWD
```

Acceptance check:

- No secrets, private hostnames, private IPs, bootstrap credentials, or personal tokens in tracked history.
- If history contains sensitive data, rotate affected secrets and rewrite history before public release.

## Phase 7 — Publication tasks

### 7.1 Add open-source metadata

Create or update:

- `SECURITY.md` with vulnerability reporting process.
- `CODE_OF_CONDUCT.md` if desired.
- `THIRD_PARTY_NOTICES.md`.
- `CHANGELOG.md` or release notes for the fork delta.
- `.github/dependabot.yml` review for correct package ecosystem and schedule.

Acceptance check:

- README links to these files.

### 7.2 Prepare first public release

Implementation:

- Ensure GHCR workflow publishes under the intended public repository.
- Confirm package visibility will be public.
- Confirm Actions permissions are minimal and pinned actions remain pinned.
- Tag release only after CI is green:
  - `v0.1.0` or similar.
- Add release notes covering:
  - Fork attribution.
  - Major redesign changes.
  - Known limitations.
  - Upgrade caveats from Once Campfire.

Acceptance check:

- Public repo page renders README correctly.
- Public Docker image can be pulled and started by a third party.
