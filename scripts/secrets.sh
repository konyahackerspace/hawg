#!/usr/bin/env bash
# Secrets helper for the hawg repo. See docs/secrets-management.md for the full story.
#
# Usage:
#   ./scripts/secrets.sh decrypt   # secrets/secrets.enc.yaml -> esphome/secrets.yaml
#   ./scripts/secrets.sh encrypt   # esphome/secrets.yaml -> secrets/secrets.enc.yaml
#   ./scripts/secrets.sh edit      # edit encrypted file in place ($EDITOR, never plaintext on disk)
#   ./scripts/secrets.sh rekey     # re-encrypt after .sops.yaml key list changed
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENC_FILE="$REPO_ROOT/secrets/secrets.enc.yaml"
PLAIN_FILE="$REPO_ROOT/esphome/secrets.yaml"

die() { echo "error: $*" >&2; exit 1; }

command -v sops >/dev/null || die "sops not installed (brew install sops age)"

# On macOS sops defaults to ~/Library/Application Support/sops/age/keys.txt;
# our docs put the key at the XDG path. Point sops there if that's where it is.
if [ -z "${SOPS_AGE_KEY_FILE:-}" ] && [ -f "$HOME/.config/sops/age/keys.txt" ]; then
  export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
fi
[ -f "$REPO_ROOT/.sops.yaml" ] || die "no .sops.yaml found — are you in the hawg repo?"

case "${1:-}" in
  decrypt)
    [ -f "$ENC_FILE" ] || die "$ENC_FILE not found"
    sops -d "$ENC_FILE" > "$PLAIN_FILE"
    echo "decrypted -> $PLAIN_FILE (gitignored)"
    ;;
  encrypt)
    [ -f "$PLAIN_FILE" ] || die "$PLAIN_FILE not found — nothing to encrypt"
    # --filename-override: match the .sops.yaml rule for the *encrypted* path,
    # since the plaintext input lives elsewhere
    sops -e --filename-override "$ENC_FILE" "$PLAIN_FILE" > "$ENC_FILE"
    echo "encrypted -> $ENC_FILE (commit this)"
    ;;
  edit)
    sops "$ENC_FILE"
    echo "remember to run: $0 decrypt  (to refresh your local plaintext copy)"
    ;;
  rekey)
    sops updatekeys "$ENC_FILE"
    echo "re-encrypted for the keys currently listed in .sops.yaml — commit the result"
    ;;
  *)
    grep '^#   ' "$0" | sed 's/^#   //'
    exit 1
    ;;
esac
