#!/usr/bin/env bash
# Publish every mooncake in this monorepo to mooncakes.io in dependency
# order, refreshing the registry index between each publish so the next
# package can resolve the version we just shipped.
#
# Why `moon update` between publishes:
#   `moon publish` for `sol` requires the registry index to know about
#   the just-published `mizchi/luna@X.Y.Z`. Without a `moon update` in
#   between, moon's local index still claims the older luna is the
#   latest, the dep resolver chokes, and the publish fails. Same goes
#   for sol_adapter_* depending on sol.
#
# Order: dependency-leaves first.
#   luna  →  luna_components  →  astra  →  sol  →  sol_adapter_*
#
# Usage:
#   ./scripts/release-mooncakes.sh
#   ./scripts/release-mooncakes.sh --dry-run    # print the plan, don't publish
#
# Prerequisite: `just vup patch --release` (or equivalent) must have
# already created the commit + per-package tags locally, and `git push
# --tags` must have landed them on origin if the registry validates
# against the tag.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Dependency-ordered publish list.
PACKAGES=(
  luna
  luna_components
  astra
  sol
  sol_adapter_cloudflare
  sol_adapter_node
)

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    echo "  \$ $*"
    "$@"
  fi
}

# `moon publish` with a 409-duplicate-version skip. The coordinated bump
# in `vup --release` advances every package's version even when only a
# subset has actual changes; the unchanged ones can collide with what
# the registry already serves. Treat that specific failure mode as a
# skip, not a hard error — every other failure still aborts the script.
publish_pkg() {
  local pkg="$1"
  local version="$2"
  local output status
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] (cd $pkg && moon publish)"
    return 0
  fi
  echo "  \$ (cd $pkg && moon publish)"
  set +e
  output=$(cd "$pkg" && moon publish 2>&1)
  status=$?
  set -e
  echo "$output"
  if [[ "$status" -eq 0 ]]; then
    return 0
  fi
  if echo "$output" | grep -qE "Version Error|duplicated with an existing version|409 Conflict"; then
    echo "  -> $pkg @ $version is already on the registry; skipping."
    return 0
  fi
  echo "  -> moon publish failed for $pkg @ $version (status=$status)"
  return "$status"
}

for pkg in "${PACKAGES[@]}"; do
  if [[ ! -f "$pkg/moon.mod.json" ]]; then
    echo "Skipping $pkg (no moon.mod.json)"
    continue
  fi
  version=$(node -p "require('./$pkg/moon.mod.json').version")
  echo ""
  echo "=== Publishing $pkg @ $version ==="
  publish_pkg "$pkg" "$version"
  echo "=== Refreshing registry index (moon update) ==="
  run moon update
done

echo ""
echo "All mooncakes published (skipped any that were already on the registry)."
