#!/usr/bin/env bash
#
# deploy.sh -- push this provisioning dir to a host and run bootstrap.sh there.
#
#   ./deploy.sh myserver --check           # dry run against myserver
#   ./deploy.sh myserver --yes             # install everything missing
#   ./deploy.sh myserver --only dotfiles   # just refresh dotfiles
#
# Runs on your laptop. Requires ssh access to HOST.
set -euo pipefail

HOST="${1:?usage: ./deploy.sh HOST [bootstrap args...]}"; shift || true
SRC="$(cd "$(dirname "$0")" && pwd)"
REMOTE_DIR=".server-setup"

echo "==> syncing $SRC -> $HOST:~/$REMOTE_DIR"
rsync -az --delete \
  --exclude '.git' --exclude 'secrets.sh' --exclude '*.bak-*' \
  -e ssh "$SRC/" "$HOST:$REMOTE_DIR/"

# Terminals like ghostty/kitty set TERM to an entry older distros lack, which breaks
# htop/vim/tmux over ssh. Copy ours into the host's ~/.terminfo if it's missing.
case " $* " in *" --check "*|*" -n "*) CHECK=1 ;; *) CHECK=0 ;; esac
if [ "$CHECK" = 0 ] && [ -n "${TERM:-}" ] && infocmp -x "$TERM" >/dev/null 2>&1 \
   && ! ssh "$HOST" "infocmp '$TERM'" >/dev/null 2>&1; then
  echo "==> installing terminfo for $TERM on $HOST"
  infocmp -x "$TERM" | ssh "$HOST" 'tic -x - 2>/dev/null' || echo "    (terminfo install failed; use TERM=xterm-256color)"
fi

echo "==> running bootstrap.sh on $HOST"
# -t for interactive prompts; pass through all remaining args.
ssh -t "$HOST" "cd ~/$REMOTE_DIR && ./bootstrap.sh $*"
