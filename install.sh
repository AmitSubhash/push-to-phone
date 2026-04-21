#!/usr/bin/env bash
# install.sh: symlink bin/push-to-phone into ~/.local/bin
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$HERE/bin/push-to-phone"
BIN_DST="$HOME/.local/bin/push-to-phone"

if [[ ! -x "$BIN_SRC" ]]; then
  chmod +x "$BIN_SRC"
fi

mkdir -p "$HOME/.local/bin"

if [[ -e "$BIN_DST" || -L "$BIN_DST" ]]; then
  echo "Removing existing $BIN_DST"
  rm -f "$BIN_DST"
fi

ln -s "$BIN_SRC" "$BIN_DST"
echo "Linked $BIN_DST -> $BIN_SRC"

# PATH check
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    echo
    echo "WARNING: \$HOME/.local/bin is not on your PATH."
    echo "Add this to your shell rc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

echo
echo "Done. Try:  push-to-phone -t 'Test' 'https://example.com'"
