#!/bin/bash
set -euo pipefail

# Install script for the Node.js APT repository
# Usage: curl -fsSL https://xi72yow.github.io/nodejs-deb/install.sh | sudo bash
#
# After install, run: node-use 24  (or 22, etc.)
# Requires a new login shell for node-use to be available.

REPO_URL="${REPO_URL:-https://xi72yow.github.io/nodejs-deb}"

echo "Adding Node.js APT repository..."

# Download and install the GPG key
curl -fsSL "${REPO_URL}/key.gpg" | gpg --dearmor -o /usr/share/keyrings/nodejs-deb.gpg

# Add the repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nodejs-deb.gpg] ${REPO_URL} stable main" \
  > /etc/apt/sources.list.d/nodejs.list

apt-get update

# Install all available nodejs versions
apt-get install -y nodejs-*

echo ""
echo "Node.js installed successfully!"
echo "Switch version:  node-use 24  (or 22, etc.)"
echo "List versions:   node-use"
echo ""
echo "Start a new shell for node-use to be available."
