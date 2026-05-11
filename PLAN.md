# once-campfire Internet Deployment Plan

Goal: run Once Campfire safely on the Mac mini (`100.96.43.39`, `mini.tail148d59.ts.net`) using Kamal, expose it through the existing Cloudflare Tunnel for `gammalabs.cc`, and keep the setup easy to modify and redeploy over time.

## Current findings

- Local checkout is on `main`; `origin` is now `tjansn/once-campfire` and `upstream` is `basecamp/once-campfire`.
- The app is a Rails/Campfire Docker app.
- Runtime processes are managed by `Procfile`: web, Redis, and Resque workers in one container.
- Persistent data lives in `/rails/storage` inside the container:
  - SQLite database: `/rails/storage/db/production.sqlite3`
  - file uploads: `/rails/storage/files`
- Health check endpoint is `/up`.
- Initial Kamal config now exists at `config/deploy.yml`.
- Local Docker is running via OrbStack.
- Kamal is available through `bin/kamal`, which currently uses Nix-provided Kamal 2.10.1.
- The mini is reachable over Tailscale and port 22 is open, but SSH authentication currently fails.
- `gammalabs.cc` is Cloudflare-proxied and currently returns Cloudflare `530`, consistent with an unavailable tunnel/origin.

## Target architecture

```text
Internet
  -> Cloudflare TLS / Cloudflare Tunnel for gammalabs.cc
  -> cloudflared on Mac mini
  -> localhost-bound Kamal proxy on Mac mini
  -> Campfire app container
  -> persistent Docker volume mounted at /rails/storage
```

Security goals:

- Do not expose Campfire directly on public ports if Cloudflare Tunnel can be the ingress.
- Bind the Kamal proxy to localhost or Tailscale-only where possible.
- Keep admin first-run protected before public traffic reaches the app.
- Store secrets outside git.
- Preserve `/rails/storage` across deploys.
- Add backups before treating the instance as durable.

## Progress so far

- Created fork: `tjansn/once-campfire`.
- Updated remotes: `origin` is the fork, `upstream` is `basecamp/once-campfire`.
- Added `config/deploy.yml` for Kamal.
- Added `.kamal/secrets.example` and created local ignored `.kamal/secrets` with generated `SECRET_KEY_BASE` and VAPID keys.
- Added `bin/kamal` wrapper for repeatable Kamal usage.
- Validated Kamal config.
- Built the production Docker image locally for `linux/arm64`.
- Smoke-tested the built container locally on `http://127.0.0.1:8081/up`.
- Remaining hard blockers: SSH access to the mini and a registry token for GHCR deploys.

## Step-by-step plan

### 1. Establish SSH access to the Mac mini

Status: **blocked** until SSH auth works.

Tasks:

- Add this machine's public SSH key to the correct user on the mini, or enable Tailscale SSH.
- Verify access with:

```bash
ssh <user>@mini.tail148d59.ts.net 'whoami; hostname; sw_vers; uname -m'
```

Public key currently offered by this machine:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILTqHbs23NNr5//FKNIZN2Rl1zUuAaD1iPsCZPeW4/+j GH Tom MBP
```

### 2. Inspect and prepare the Mac mini

Tasks after SSH works:

- Confirm OS, architecture, disk, memory, and current services.
- Confirm Docker is installed and running.
- Confirm whether `cloudflared` is installed and how it is managed (`launchd`, manual service, etc.).
- Confirm firewall/listening ports.
- Decide which local user Kamal should SSH as.
- Ensure the deploy user can run Docker commands.

Checks:

```bash
sw_vers
uname -m
df -h /
sysctl -n hw.memsize
command -v docker && docker version && docker info
command -v cloudflared && cloudflared --version
launchctl list | grep -i cloudflared || true
lsof -nP -iTCP -sTCP:LISTEN
```

### 3. Create our own deployable source repo

Status: **done**.

Tasks:

- Fork `basecamp/once-campfire` to a writable repo, e.g. `tjansn/once-campfire`.
- Update git remotes:

```bash
git remote rename origin upstream
git remote add origin git@github.com:tjansn/once-campfire.git
git fetch --all
```

- Keep `upstream` for Basecamp updates and `origin` for our changes.

### 4. Install local deployment tooling

Status: **mostly done**. Docker is running and `bin/kamal` works via Nix. A GHCR token is still needed before pushing/deploying.

Tasks:

- Start local Docker daemon / OrbStack.
- Install Kamal 2.x.
- Verify GitHub Container Registry or Docker Hub credentials.
- Prefer GHCR or Docker Hub over Kamal's local registry for this macOS target.

Checks:

```bash
docker version
bin/kamal version
```

### 5. Add Kamal configuration

Status: **done initial version**. Final SSH user and Cloudflare Tunnel details may still be adjusted after mini inspection.

Files to add/update:

- `config/deploy.yml`
- `.kamal/secrets` or `.kamal/secrets-common` template only, with real secrets ignored
- `.gitignore` and `.dockerignore` entries for `.kamal/secrets*`

Initial Kamal shape:

```yaml
service: campfire
image: tjansn/once-campfire

servers:
  web:
    hosts:
      - mini.tail148d59.ts.net

proxy:
  host: gammalabs.cc
  app_port: 80
  ssl: false
  forward_headers: true
  healthcheck:
    path: /up
  run:
    http_port: 8080
    https_port: 8443
    bind_ips:
      - 127.0.0.1

registry:
  server: ghcr.io
  username: tjansn
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: arm64

volumes:
  - campfire_storage:/rails/storage

env:
  clear:
    DISABLE_SSL: ""
    SKIP_TELEMETRY: "1"
    RAILS_LOG_LEVEL: info
    RAILS_MAX_THREADS: "5"
    WEB_CONCURRENCY: "2"
  secret:
    - SECRET_KEY_BASE
    - VAPID_PUBLIC_KEY
    - VAPID_PRIVATE_KEY
```

Notes:

- Exact proxy settings may change after inspecting the existing Cloudflare Tunnel.
- `DISABLE_SSL` should remain blank/absent if Cloudflare forwards `X-Forwarded-Proto: https`; Rails then uses secure cookies and assumes SSL.
- If local health checks are only HTTP and Rails redirects them, we may set `DISABLE_SSL=1` temporarily or adjust proxy/header behavior after testing.

### 6. Generate and store secrets

Status: **partial**. `SECRET_KEY_BASE` and VAPID keys are generated locally in ignored `.kamal/secrets`; a registry token still needs to be supplied.

Required:

- `SECRET_KEY_BASE`: must remain stable forever for cookies/signed data.
- `KAMAL_REGISTRY_PASSWORD`: GHCR PAT or Docker registry token with package push/pull permissions.

Generated:

- `VAPID_PUBLIC_KEY` and `VAPID_PRIVATE_KEY` for web push notifications.

Generate examples:

```bash
openssl rand -hex 64
# VAPID can be generated inside the app container or with script/admin/create-vapid-key once dependencies are available.
```

Secrets must not be committed.

### 7. Configure Cloudflare Tunnel safely

Tasks:

- Inspect current tunnel config on the mini.
- Point `gammalabs.cc` to the local Kamal proxy, likely:

```yaml
ingress:
  - hostname: gammalabs.cc
    service: http://127.0.0.1:8080
  - service: http_status:404
```

- Keep Cloudflare as the public TLS endpoint.
- Prefer Cloudflare Access during first run so random internet visitors cannot claim the first admin account.

### 8. First deployment

Tasks:

- Run Kamal setup/deploy.
- Verify proxy and app containers.
- Verify health check.
- Verify Cloudflare Tunnel reaches the app.

Commands:

```bash
bin/kamal config
bin/kamal setup
bin/kamal app details
bin/kamal proxy details
curl -I https://gammalabs.cc/up
```

### 9. First-run admin bootstrap

Tasks:

- Keep app protected by Cloudflare Access or reachable only privately.
- Visit the app and create the first admin user.
- Confirm login, rooms, uploads, ActionCable/chat, and push metadata.
- Only then open public access policy as desired.

### 10. Backups and recovery

Tasks:

- Use Campfire's `script/admin/prepare-backup` to create SQLite backups.
- Also back up uploaded files under `/rails/storage/files`.
- Store backups off the mini, ideally over Tailscale.
- Schedule backups with `launchd` or a simple host-side script.
- Test restore procedure before relying on the instance.

### 11. Ongoing deploy workflow

Normal workflow:

```bash
git checkout -b feature/my-change
# edit/test locally
git commit -am "Describe change"
git push origin feature/my-change
# merge to main when ready
git checkout main
git pull
kamal deploy
```

Upstream update workflow:

```bash
git fetch upstream
git checkout main
git merge upstream/main
# resolve/test
kamal deploy
```

## Blockers / decisions needed

1. SSH access to the mini must be enabled.
2. Choose registry: GHCR is recommended if we create/use a writable GitHub repo.
3. Confirm whether Cloudflare Tunnel should stay host-managed or be managed as a Kamal accessory.
4. Decide whether `gammalabs.cc` should be fully public after bootstrap or protected with Cloudflare Access.
