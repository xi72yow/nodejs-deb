# Node.js version switching (per-user, no sudo required)
# Installed by nodejs-deb packages to /etc/profile.d/node-use.sh
# Sourced automatically on login shell start

# EOL dates for Node.js major versions (update when adding/removing versions)
# Source: https://github.com/nodejs/release#release-schedule
_NODE_EOL_18="2025-04-30"
_NODE_EOL_20="2026-04-30"
_NODE_EOL_22="2027-04-30"
_NODE_EOL_24="2028-04-30"

_node_check_eol() {
  local version="$1"
  local eol_var="_NODE_EOL_${version}"
  local eol_date="${!eol_var:-}"

  if [ -z "$eol_date" ]; then
    return
  fi

  local today
  today=$(date +%Y-%m-%d)

  if [[ "$today" > "$eol_date" || "$today" == "$eol_date" ]]; then
    echo ""
    echo "  WARNING: Node.js ${version} reached End-of-Life on ${eol_date}."
    echo "  This version no longer receives security updates."
    echo "  Please switch to a supported version: node-use"
    echo ""
  fi
}

node-use() {
  local version="$1"

  if [ -z "$version" ]; then
    echo "Usage: node-use <major-version>"
    echo "Example: node-use 24"
    echo ""
    echo "Installed versions:"
    for d in /usr/lib/nodejs-*/bin/node; do
      [ -x "$d" ] || continue
      local v="${d#/usr/lib/nodejs-}"
      v="${v%%/*}"
      local current=""
      if command -v node >/dev/null 2>&1 && [ "$(command -v node)" = "/usr/lib/nodejs-${v}/bin/node" ]; then
        current=" (active)"
      fi
      local eol_var="_NODE_EOL_${v}"
      local eol_date="${!eol_var:-}"
      local eol_info=""
      if [ -n "$eol_date" ]; then
        local today
        today=$(date +%Y-%m-%d)
        if [[ "$today" > "$eol_date" || "$today" == "$eol_date" ]]; then
          eol_info=" [EOL since ${eol_date}]"
        fi
      fi
      echo "  ${v} — $($d --version)${current}${eol_info}"
    done
    return 0
  fi

  local node_dir="/usr/lib/nodejs-${version}"

  if [ ! -d "$node_dir" ]; then
    echo "nodejs-${version} is not installed." >&2
    echo "Available:" >&2
    for d in /usr/lib/nodejs-*/bin/node; do
      [ -x "$d" ] || continue
      local v="${d#/usr/lib/nodejs-}"
      echo "  ${v%%/*}" >&2
    done
    return 1
  fi

  # Remove any existing nodejs paths from PATH
  PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/usr/lib/nodejs-' | tr '\n' ':' | sed 's/:$//')

  # Prepend selected version
  export PATH="${node_dir}/bin:${PATH}"

  # Persist for new shells
  echo "$version" > "${HOME}/.node-version"

  echo "Node $(node --version) active (npm $(npm --version))"

  # Warn if EOL
  _node_check_eol "$version"
}

# On shell start: restore last used version from ~/.node-version
if [ -f "${HOME}/.node-version" ]; then
  _node_v=$(cat "${HOME}/.node-version")
  if [ -d "/usr/lib/nodejs-${_node_v}/bin" ]; then
    PATH="/usr/lib/nodejs-${_node_v}/bin:${PATH}"
    # Show EOL warning on shell start too
    _node_check_eol "$_node_v"
  fi
  unset _node_v
fi
