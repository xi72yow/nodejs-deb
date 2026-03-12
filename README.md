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

## Static linking

The packages use official Node.js tarballs from nodejs.org, which bundle dependencies like OpenSSL, ICU, libuv, zlib, and others statically. Only base system libraries (libc6, libstdc++6, libgcc-s1) remain dynamically linked.

This is a deliberate choice: different Node.js versions require different versions of these libraries, and bundling them avoids dependency conflicts when running multiple versions side by side. The trade-off is that security patches for bundled libraries (e.g. OpenSSL) come through new Node.js releases rather than system-wide `apt upgrade`. Since this repository only offers actively supported versions (LTS + Current), which receive regular upstream security updates, this is effectively a non-issue.

## Security

- Tarballs are downloaded from `nodejs.org` and verified against official `SHASUMS256.txt`
- Repository is GPG-signed
- Builds run in GitHub Actions (public, auditable)
