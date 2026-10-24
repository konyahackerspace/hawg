#!/usr/bin/env bash
# Deploy homeassistant/ to the HA Pi. See docs/home-assistant.md for the full story.
#
# Usage:
#   ./scripts/deploy-ha.sh          # copy config, validate, restart HA
#   ./scripts/deploy-ha.sh --check  # copy config and validate, then put the old config back
#
# Needs the "Terminal & SSH" add-on with your SSH public key, and decrypted secrets
# (./scripts/secrets.sh decrypt). Override the target with HA_SSH=user@host
# (default: root@192.168.0.100 — not homeassistant.local, the hackerspace has several HAs).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/homeassistant"
HA_SSH="${HA_SSH:-root@192.168.0.100}"

die() { echo "error: $*" >&2; exit 1; }

case "${1:-}" in
  "") MODE=deploy ;;
  --check) MODE=check ;;
  *) grep '^#   ' "$0" | sed 's/^#   //'; exit 1 ;;
esac

[ -f "$SRC/configuration.yaml" ] || die "$SRC/configuration.yaml not found"
[ -f "$SRC/secrets.yaml" ] || die "$SRC/secrets.yaml not found — run ./scripts/secrets.sh decrypt"

# Only the paths we manage are touched; .storage, the database etc. are left alone.
# The previous version is kept in /config/.hawg-prev so a failed check can be undone.
REMOTE=$(cat <<'EOF'
set -eu
cd /config
rm -rf .hawg-prev && mkdir .hawg-prev
[ -e configuration.yaml ] && cp -p configuration.yaml .hawg-prev/
[ -e packages ] && cp -rp packages .hawg-prev/
[ -e secrets.yaml ] && cp -p secrets.yaml .hawg-prev/

restore() {
  rm -rf configuration.yaml packages secrets.yaml
  cp -rp .hawg-prev/. .
}

rm -rf packages
tar -xzf -

if ! ha core check; then
  restore
  echo "config check failed — previous config restored" >&2
  exit 1
fi

if [ "$MODE" = check ]; then
  restore
  echo "config check passed (nothing deployed)"
else
  ha core restart
  echo "deployed and restarted"
fi
EOF
)

# The remote script goes in as the ssh command so stdin stays free for the tarball.
# HostKeyAlias keeps this Pi's host key apart from other homeassistant.local boxes.
tar -C "$SRC" -czf - configuration.yaml packages secrets.yaml \
  | ssh -o HostKeyAlias=hawg-ha "$HA_SSH" "MODE=$MODE; $REMOTE"
