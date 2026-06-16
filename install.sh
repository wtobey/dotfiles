#!/usr/bin/env bash
# install.sh — run by Coder's dotfiles personalization on every workspace start.
# Must stay executable (chmod +x); Coder skips a non-executable script.
#
# Installs the Agent of Empires (aoe) CLI for this user. It re-runs on every start, so it
# must be idempotent: no-op when aoe is already present.
set -euo pipefail

log() { echo "[dotfiles] $*" >&2; }

# Ensure the xterm-ghostty terminfo entry exists. We connect from Ghostty, which
# sets TERM=xterm-ghostty, but remote workspaces don't ship that terminfo — so
# `tmux attach` (hence aoe's tmux and live session views) dies with
# "missing or unsuitable terminal: xterm-ghostty". Derive it from xterm-256color,
# which Ghostty is compatible with. Runs before the aoe early-exit below so it
# applies even when aoe is already installed. Idempotent: skips if resolvable.
if ! infocmp xterm-ghostty >/dev/null 2>&1; then
  log "installing xterm-ghostty terminfo (tmux/aoe attach prerequisite)"
  infocmp -x xterm-256color \
    | sed -E 's/^xterm-256color\|[^,]*,/xterm-ghostty|Ghostty (xterm-256color fallback),/' \
    | tic -x -o "$HOME/.terminfo" -
fi

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
