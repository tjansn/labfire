---
name: labfire-deploy
description: Project-specific deployment workflow for Labfire using Kamal. Use when asked to deploy Labfire, redeploy, merge a deployment branch to main, push release commits, check deployment status, or troubleshoot Kamal image/SSH issues for this project.
---

# Labfire Deploy

Use this skill for deployment work in the Labfire repository.

## Safety rules

- Do not print, copy, commit, or summarize secrets, credentials, private keys, tokens, private hostnames, IP addresses, or local-only deployment values.
- Treat `config/deploy.local.yml`, `.kamal/secrets`, `.kamal/secrets-*`, `.env`, and generated env files as private.
- Prefer commands that rely on existing local config instead of reading private config files.
- If command output includes private deployment details, summarize results without repeating those values.
- Do not edit public deployment templates with machine-specific values.

## Important files

- Public deployment template: `config/deploy.yml`
- Ignored local deployment config: `config/deploy.local.yml`
- Kamal wrapper: `bin/kamal`
- Production image is built from `Dockerfile`
- `.gitignore` intentionally excludes local deploy config and secrets

## Preflight

From the repo root:

```bash
git status --short --branch
git fetch origin
```

Before deploying a release, confirm:

- The intended branch is checked out, normally `main` for production deploys.
- The working tree is clean, or the user explicitly asked to deploy local uncommitted changes.
- `main` is up to date with `origin/main` after any requested merge/push.
- The local deployment config exists:

```bash
test -f config/deploy.local.yml
```

If code changed since the last verification, run the usual checks before deploying unless the user asks to skip them:

```bash
bin/test
bin/rubocop
bin/brakeman -q
git diff --check
```

## Merge and push flow

When the user asks to deploy a branch such as `refactor` to production:

```bash
git checkout refactor
git status --short --branch
git push origin refactor

git checkout main
git pull --ff-only origin main
git merge --ff-only refactor
git push origin main
```

If fast-forward merge is not possible, stop and ask before creating a merge commit or rebasing.

## Deploy command

Use the Kamal wrapper with the local config. The option order matters:

```bash
bin/kamal deploy -c config/deploy.local.yml
```

Do not use `bin/kamal -c config/deploy.local.yml deploy`; that prints usage with this wrapper/Kamal invocation.

If a specific SSH agent is required, set `KAMAL_SSH_AUTH_SOCK` for the command instead of changing committed files:

```bash
KAMAL_SSH_AUTH_SOCK="$SSH_AUTH_SOCK" bin/kamal deploy -c config/deploy.local.yml
```

`bin/kamal` copies `KAMAL_SSH_AUTH_SOCK` into `SSH_AUTH_SOCK` only when it points to an existing socket.

## Redeploying the current commit

Only use `--skip-push` when the image tag for the current commit is already present in the registry:

```bash
bin/kamal deploy -c config/deploy.local.yml --skip-push
```

If `--skip-push` fails with `manifest unknown`, run the full deploy command without `--skip-push` so Kamal builds and pushes the image first.

## Verify after deploy

A successful deploy should show Kamal completing health checks, switching proxy target, pruning, releasing the deploy lock, and finishing with exit status 0.

Useful follow-up commands:

```bash
git status --short --branch
git log --oneline -3 --decorate
bin/kamal app details -c config/deploy.local.yml
bin/kamal app logs -c config/deploy.local.yml --lines 100
```

Use status/details/log commands carefully because they may display private hostnames or operational details. Redact or summarize in user-facing responses.

## User-facing summary

After deployment, report concisely:

- Whether the deploy succeeded or failed.
- The deployed commit SHA and subject.
- Any checks run.
- Any action needed from the user.

Do not include private hostnames, IP addresses, tokens, local socket paths, or secret values in the final summary.
