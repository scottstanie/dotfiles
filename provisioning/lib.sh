# lib.sh -- helpers sourced by bootstrap.sh
# shellcheck shell=bash

if [ -t 1 ]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLU=$'\033[34m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; BLU=''; DIM=''; RST=''
fi

info()  { printf '%s==>%s %s\n' "$BLU" "$RST" "$*"; }
ok()    { printf '  %s[ ok ]%s %s\n' "$GRN" "$RST" "$*"; }
miss()  { printf '  %s[miss]%s %s\n' "$YEL" "$RST" "$*"; }
err()   { printf '  %s[fail]%s %s\n' "$RED" "$RST" "$*" >&2; }
have()  { command -v "$1" >/dev/null 2>&1; }

# sudo prefix (empty when root, unset when unavailable to a non-root user)
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if have sudo; then SUDO="sudo"; fi
fi

# confirm "message" -> 0 if user says yes (auto-yes when ASSUME_YES=1)
confirm() {
  [ "${ASSUME_YES:-0}" = "1" ] && return 0
  if [ ! -t 0 ]; then
    miss "not a TTY; re-run with --yes to install '$1'"
    return 1
  fi
  printf '  install %s? [y/N] ' "$1"
  read -r ans
  case "$ans" in [yY]*) return 0 ;; *) return 1 ;; esac
}

# place SRC DEST -- copy a dotfile idempotently, backing up an existing different file
place() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
    return 0                       # already identical
  fi
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    cp -a "$dest" "${dest}.bak-$(date +%Y%m%d%H%M%S)"
  fi
  cp -f "$src" "$dest"
}
