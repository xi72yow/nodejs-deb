#!/bin/bash
set -euo pipefail

# Build versioned .deb packages from official Node.js tarballs
# Usage: ./scripts/build-deb.sh <MAJOR_VERSION> [REVISION]
# Example: ./scripts/build-deb.sh 24 1
#          ./scripts/build-deb.sh 22 1

MAJOR="${1:-}"
REVISION="${2:-1}"

if [ -z "$MAJOR" ]; then
  echo "Usage: $0 <MAJOR_VERSION> [REVISION]"
  echo "Example: $0 24 1"
  exit 1
fi

# Resolve latest version for this major
echo "Fetching latest Node.js v${MAJOR}.x release..."
FULL_VERSION=$(curl -sL "https://nodejs.org/dist/index.json" \
  | jq -r "[.[] | select(.version | startswith(\"v${MAJOR}.\"))][0].version" \
  | sed 's/^v//')

if [ -z "$FULL_VERSION" ] || [ "$FULL_VERSION" = "null" ]; then
  echo "Error: No Node.js v${MAJOR}.x release found"
  exit 1
fi

echo "Building nodejs-${MAJOR} (v${FULL_VERSION}) revision ${REVISION} for amd64..."

WORKDIR=$(mktemp -d)
trap "rm -rf ${WORKDIR}" EXIT

ARCH="linux-x64"
TARBALL="node-v${FULL_VERSION}-${ARCH}.tar.xz"
TARBALL_URL="https://nodejs.org/dist/v${FULL_VERSION}/${TARBALL}"
SHASUMS_URL="https://nodejs.org/dist/v${FULL_VERSION}/SHASUMS256.txt"

# Download tarball and checksums
echo "Downloading ${TARBALL}..."
curl -fSL "${TARBALL_URL}" -o "${WORKDIR}/${TARBALL}"

echo "Downloading SHASUMS256.txt..."
curl -fSL "${SHASUMS_URL}" -o "${WORKDIR}/SHASUMS256.txt"

# Verify SHA256 checksum
echo "Verifying checksum..."
cd "${WORKDIR}"
grep "${TARBALL}" SHASUMS256.txt | sha256sum -c -
cd - > /dev/null

echo "Checksum OK."

# Build package structure
DEB_VERSION="${FULL_VERSION}-${REVISION}"
PKG_NAME="nodejs-${MAJOR}"
PKG_DIR="${WORKDIR}/${PKG_NAME}_${DEB_VERSION}_amd64"

mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/lib/nodejs-${MAJOR}"
mkdir -p "${PKG_DIR}/usr/share/doc/${PKG_NAME}"

# Extract Node.js tarball
echo "Extracting..."
tar -xJf "${WORKDIR}/${TARBALL}" --strip-components=1 -C "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/"

# Remove unnecessary files to save space
rm -rf "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/share/man"
rm -rf "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/share/doc"
rm -rf "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/share/systemtap"
rm -rf "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/include"
rm -f "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/CHANGELOG.md"
rm -f "${PKG_DIR}/usr/lib/nodejs-${MAJOR}/README.md"

# Copyright file
cat > "${PKG_DIR}/usr/share/doc/${PKG_NAME}/copyright" << CPEOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Node.js
Upstream-Contact: Node.js Contributors
Source: https://nodejs.org

Files: *
Copyright: Node.js contributors
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
CPEOF

# Changelog
{
  echo "${PKG_NAME} (${DEB_VERSION}) stable; urgency=medium"
  echo ""
  echo "  * Node.js v${FULL_VERSION} (Major ${MAJOR})"
  echo ""
  echo " -- nodejs-deb repository <noreply@github.com>  $(date -R)"
} > "${PKG_DIR}/usr/share/doc/${PKG_NAME}/changelog.Debian"
gzip -9n "${PKG_DIR}/usr/share/doc/${PKG_NAME}/changelog.Debian"

# Control file
INSTALLED_SIZE=$(du -sk "${PKG_DIR}" | cut -f1)

cat > "${PKG_DIR}/DEBIAN/control" << CTLEOF
Package: ${PKG_NAME}
Version: ${DEB_VERSION}
Architecture: amd64
Maintainer: nodejs-deb repository <noreply@github.com>
Installed-Size: ${INSTALLED_SIZE}
Depends: libc6, libstdc++6, libgcc-s1, nodejs-common
Section: javascript
Priority: optional
Homepage: https://nodejs.org
Description: Node.js v${MAJOR}.x runtime environment
 Node.js v${FULL_VERSION} installed to /usr/lib/nodejs-${MAJOR}/.
 Use 'node-use ${MAJOR}' to activate this version (per-user PATH switching).
 Multiple versions can be installed side by side.
CTLEOF

# Build .deb
dpkg-deb --build --root-owner-group "${PKG_DIR}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/../packages"
mkdir -p "${OUTPUT_DIR}"
mv "${PKG_DIR}.deb" "${OUTPUT_DIR}/${PKG_NAME}_${DEB_VERSION}_amd64.deb"

echo "Built: packages/${PKG_NAME}_${DEB_VERSION}_amd64.deb"
echo "${PKG_NAME}=${DEB_VERSION}" >> "${OUTPUT_DIR}/.built-versions"
