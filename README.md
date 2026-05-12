# Labfire

Labfire is a fork/derivative of Basecamp/37signals Once Campfire. It is not affiliated with or endorsed by 37signals. Labfire keeps the self-hosted team chat foundation and adds fork-specific branding and deployment defaults.

## Features

- Multiple rooms with access controls
- Direct messages
- File attachments with previews
- Search
- Web Push notifications
- @mentions
- Bot integrations through the API

## Running in development

```bash
bin/setup
bin/rails server
```

The app uses Ruby 3.4. If your system Ruby is older, the provided `bin/test` wrapper can enter a Nix shell with the required Ruby, libvips, SQLite, and ffmpeg packages.

## Deploying with Docker

Labfire's Docker image contains the web app, background jobs, Redis, file serving, and optional TLS termination. Persist the database and file attachments by mapping a volume to `/rails/storage`.

Environment variables:

- `SECRET_KEY_BASE` - required in production.
- `TLS_DOMAIN` - enable automatic TLS via Thruster for the given domain.
- `DISABLE_SSL` - set to any non-empty value to serve plain HTTP behind your own TLS proxy.
- `VAPID_PUBLIC_KEY`/`VAPID_PRIVATE_KEY` - Web Push keypair. Generate with `/script/admin/create-vapid-key`.
- `VAPID_SUBJECT` - optional Web Push subject, e.g. `mailto:admin@example.com`.
- `SENTRY_DSN` - optional Sentry error reporting DSN.

Example:

```bash
docker build -t labfire .

docker run \
  --publish 80:80 --publish 443:443 \
  --restart unless-stopped \
  --volume labfire:/rails/storage \
  --env SECRET_KEY_BASE=$YOUR_SECRET_KEY_BASE \
  --env VAPID_PUBLIC_KEY=$YOUR_PUBLIC_KEY \
  --env VAPID_PRIVATE_KEY=$YOUR_PRIVATE_KEY \
  --env VAPID_SUBJECT=mailto:admin@example.com \
  --env TLS_DOMAIN=chat.example.com \
  labfire
```

## Deploying with Kamal

`config/deploy.yml` is a generic Kamal template. Replace `YOUR_ORG`, `YOUR_HOST`, and `YOUR_DOMAIN`, or copy local/private values to ignored files such as `config/deploy.local.yml`. Keep `.kamal/secrets*` untracked.

## First run

When you start Labfire for the first time, you’ll be guided through creating an admin account. The email address for that account is shown on the login page so people who forget their password know who to contact.

Labfire is single-tenant: rooms designated public are accessible by all users in the system. Deploy separate instances for separate organizations.

## Upgrading from upstream

Track the Once Campfire upstream remote and merge or cherry-pick intentionally. Review schema changes, initializers, assets, and license/notice updates before deploying.

## Security

Please report vulnerabilities privately according to [SECURITY.md](SECURITY.md) once configured for your public repository. Do not include secrets, private hosts, or credentials in issues or discussions.

## License and notices

Labfire is distributed under the MIT license. See [MIT-LICENSE](MIT-LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for upstream attribution and bundled third-party asset notices.
