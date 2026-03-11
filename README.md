# nodejs-deb

Unofficial APT repository for Node.js — versioned packages with per-user switching.

**Policy:** Only supported versions (LTS + Current) are offered. EOL versions belong in containers.

## Install

```bash
curl -fsSL https://xi72yow.github.io/nodejs-deb/install.sh | sudo bash
```

Installs all supported Node.js versions (currently LTS + Current).

## Usage

```bash
node-use 24        # Switch to Node 24 (per-user, no sudo)
node-use 22        # Switch to Node 22
node-use           # List installed versions
node --version     # Verify
```

Switching persists across new shells via `~/.node-version`.

## How it works

- Each package (`nodejs-22`, `nodejs-24`) installs to `/usr/lib/nodejs-XX/`
- Multiple versions coexist — no conflicts
- `node-use` prepends the selected version's `bin/` to your `PATH`
- No sudo needed for switching, only for installing packages
- Global npm packages are isolated per version

## Build locally

```bash
./scripts/build-deb.sh 24       # Build nodejs-24 .deb
./scripts/build-deb.sh 22       # Build nodejs-22 .deb
./scripts/update-repo.sh --no-sign  # Generate unsigned repo metadata
```

## Security

- Tarballs are downloaded from `nodejs.org` and verified against official `SHASUMS256.txt`
- Repository is GPG-signed
- Builds run in GitHub Actions (public, auditable)
