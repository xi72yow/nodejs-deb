#!/bin/bash
set -euo pipefail

# Build the nodejs-common .deb package (contains node-use.sh)
# Usage: ./scripts/build-common-deb.sh [REVISION]

REVISION="${1:-1}"
VERSION="1.0.0-${REVISION}"

echo "Building nodejs-common ${VERSION} for amd64..."

WORKDIR=$(mktemp -d)
trap "rm -rf ${WORKDIR}" EXIT

PKG_DIR="${WORKDIR}/nodejs-common_${VERSION}_all"

mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/etc/profile.d"
mkdir -p "${PKG_DIR}/usr/share/doc/nodejs-common"

# node-use.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "${SCRIPT_DIR}/node-use.sh" "${PKG_DIR}/etc/profile.d/node-use.sh"
chmod 644 "${PKG_DIR}/etc/profile.d/node-use.sh"

# Copyright
cat > "${PKG_DIR}/usr/share/doc/nodejs-common/copyright" << CPEOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: nodejs-deb
Source: https://github.com/xi72yow/nodejs-deb

Files: *
Copyright: 2026 xi72yow
License: MIT
CPEOF

# Changelog
{
  echo "nodejs-common (${VERSION}) stable; urgency=medium"
  echo ""
  echo "  * node-use shell function for per-user Node.js version switching"
  echo ""
  echo " -- nodejs-deb repository <noreply@github.com>  $(date -R)"
} > "${PKG_DIR}/usr/share/doc/nodejs-common/changelog.Debian"
gzip -9n "${PKG_DIR}/usr/share/doc/nodejs-common/changelog.Debian"

# Control
INSTALLED_SIZE=$(du -sk "${PKG_DIR}" | cut -f1)

cat > "${PKG_DIR}/DEBIAN/control" << CTLEOF
Package: nodejs-common
Version: ${VERSION}
Architecture: all
Maintainer: nodejs-deb repository <noreply@github.com>
Installed-Size: ${INSTALLED_SIZE}
Section: javascript
Priority: optional
Homepage: https://github.com/xi72yow/nodejs-deb
Description: Common utilities for nodejs-deb packages
 Provides the node-use shell function for per-user Node.js version switching.
 Installed to /etc/profile.d/node-use.sh.
CTLEOF

dpkg-deb --build --root-owner-group "${PKG_DIR}"

OUTPUT_DIR="${SCRIPT_DIR}/../packages"
mkdir -p "${OUTPUT_DIR}"
mv "${PKG_DIR}.deb" "${OUTPUT_DIR}/nodejs-common_${VERSION}_all.deb"

echo "Built: packages/nodejs-common_${VERSION}_all.deb"
