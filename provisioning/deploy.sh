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

echo "==> running bootstrap.sh on $HOST"
# -t for interactive prompts; pass through all remaining args.
ssh -t "$HOST" "cd ~/$REMOTE_DIR && ./bootstrap.sh $*"
