#!/usr/bin/env bash
# install.sh — run by Coder's dotfiles personalization on every workspace start.
# Must stay executable (chmod +x); Coder skips a non-executable script.
#
# Installs the Agent of Empires (aoe) CLI for this user. It re-runs on every start, so it
# must be idempotent: no-op when aoe is already present.
set -euo pipefail

log() { echo "[dotfiles] $*" >&2; }

if command -v aoe >/dev/null 2>&1; then
  log "aoe already installed ($(aoe --version 2>/dev/null || echo 'version unknown')); skipping"
  exit 0
fi

# tmux is an aoe prerequisite. The elera-referrals-demo devcontainer bakes it in, but other
# workspaces might not, so fail loudly with a clear message rather than later inside aoe.
command -v tmux >/dev/null 2>&1 || {
  log "ERROR: tmux is required by aoe but is not installed in this workspace"
  exit 1
}

log "installing Agent of Empires (aoe)"
curl -fsSL https://raw.githubusercontent.com/agent-of-empires/agent-of-empires/main/scripts/install.sh | bash

command -v aoe >/dev/null 2>&1 \
  || log "WARNING: aoe not on PATH in this shell after install; open a new shell or check the installer output"
