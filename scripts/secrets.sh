#!/usr/bin/env bash
# Secrets helper for the hawg repo. See docs/secrets-management.md for the full story.
#
# Each encrypted file in secrets/ has a decrypted, gitignored counterpart:
#   secrets/secrets.enc.yaml       <-> esphome/secrets.yaml
#   secrets/homeassistant.enc.yaml <-> homeassistant/secrets.yaml
#
# Usage:
#   ./scripts/secrets.sh decrypt          # all encrypted files -> plaintext copies
#   ./scripts/secrets.sh encrypt          # all plaintext copies -> encrypted files
#   ./scripts/secrets.sh edit [esphome|homeassistant]  # edit in place ($EDITOR, never plaintext on disk)
#   ./scripts/secrets.sh rekey            # re-encrypt after .sops.yaml key list changed
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# target -> "encrypted plaintext" (relative to repo root)
pair() {
  case "$1" in
    esphome)       echo "secrets/secrets.enc.yaml esphome/secrets.yaml" ;;
    homeassistant) echo "secrets/homeassistant.enc.yaml homeassistant/secrets.yaml" ;;
    *) die "unknown target '$1' (esphome|homeassistant)" ;;
  esac
}
TARGETS="esphome homeassistant"

die() { echo "error: $*" >&2; exit 1; }

command -v sops >/dev/null || die "sops not installed (brew install sops age)"

# On macOS sops defaults to ~/Library/Application Support/sops/age/keys.txt;
# our docs put the key at the XDG path. Point sops there if that's where it is.
if [ -z "${SOPS_AGE_KEY_FILE:-}" ] && [ -f "$HOME/.config/sops/age/keys.txt" ]; then
  export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
fi
[ -f "$REPO_ROOT/.sops.yaml" ] || die "no .sops.yaml found — are you in the hawg repo?"
cd "$REPO_ROOT"

case "${1:-}" in
  decrypt)
    for t in $TARGETS; do
      read -r enc plain <<<"$(pair "$t")"
      [ -f "$enc" ] || die "$enc not found"
      sops -d "$enc" > "$plain"
      echo "decrypted -> $plain (gitignored)"
    done
    ;;
  encrypt)
    for t in $TARGETS; do
      read -r enc plain <<<"$(pair "$t")"
      [ -f "$plain" ] || { echo "skip: $plain not found"; continue; }
      # --filename-override: match the .sops.yaml rule for the *encrypted* path,
      # since the plaintext input lives elsewhere
      sops -e --filename-override "$enc" "$plain" > "$enc"
      echo "encrypted -> $enc (commit this)"
    done
    ;;
  edit)
    read -r enc _ <<<"$(pair "${2:-esphome}")"
    sops "$enc"
    echo "remember to run: $0 decrypt  (to refresh your local plaintext copy)"
    ;;
  rekey)
    for t in $TARGETS; do
      read -r enc _ <<<"$(pair "$t")"
      sops updatekeys -y "$enc"
    done
    echo "re-encrypted for the keys currently listed in .sops.yaml — commit the result"
    ;;
  *)
    grep '^#   ' "$0" | sed 's/^#   //'
    exit 1
    ;;
esac
