#!/usr/bin/env bash
# install.sh — run by Coder's dotfiles personalization on every workspace start.
# Must stay executable (chmod +x); Coder skips a non-executable script.
#
# Installs the Agent of Empires (aoe) CLI for this user. It re-runs on every start, so it
# must be idempotent: no-op when aoe is already present.
set -euo pipefail

log() { echo "[dotfiles] $*" >&2; }

# Directory this script lives in (the cloned dotfiles repo); used to symlink tracked
# config files into $HOME.
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink personal git config (identity, etc.) into place. Declarative config belongs
# here in dotfiles, not in a persisted volume mount. Runs before the aoe early-exit so
# it applies on every start.
ln -sf "$dotfiles_dir/.gitconfig" "$HOME/.gitconfig"

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

# Set up tmux session persistence (resurrect + continuum via TPM). In Coder
# devcontainers ~/.tmux lives in the container overlay and is wiped on every restart,
# so TPM and the plugins must be reinstalled on each start. Resurrect snapshots are
# saved under /workspaces (the persistent disk) when available, so sessions survive a
# restart. Runs before the aoe early-exit so it applies even when aoe is installed.
if command -v tmux >/dev/null 2>&1; then
  ln -sf "$dotfiles_dir/.tmux.conf" "$HOME/.tmux.conf"

  # Choose a persistent resurrect dir (durable /workspaces mount, else $HOME) and
  # record it for .tmux.conf to source.
  if [ -d /workspaces ] && [ -w /workspaces ]; then
    resurrect_dir=/workspaces/.tmux/resurrect
  else
    resurrect_dir="$HOME/.tmux/resurrect"
  fi
  mkdir -p "$resurrect_dir" "$HOME/.tmux"
  printf "set -g @resurrect-dir '%s'\n" "$resurrect_dir" > "$HOME/.tmux/resurrect-dir.conf"

  tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ ! -d "$tpm_dir" ]; then
    log "installing TPM (tmux plugin manager)"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" \
      || log "WARNING: TPM clone failed; tmux plugins unavailable this session"
  fi
  if [ -x "$tpm_dir/bin/install_plugins" ]; then
    log "installing/updating tmux plugins via TPM"
    "$tpm_dir/bin/install_plugins" >/dev/null 2>&1 \
      || log "WARNING: TPM plugin install reported an issue (prefix + I to retry inside tmux)"
  fi
fi

# Install ccremote-spawn so the ccremote Slack bot can launch a Remote Control
# session on this workspace via `coder ssh` (github.com/wtobey/ccremote). Runs
# before the aoe early-exit so it applies on every start. Idempotent: install -m
# overwrites in place.
if [ -f "$dotfiles_dir/ccremote-spawn" ]; then
  log "installing ccremote-spawn to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$dotfiles_dir/ccremote-spawn" "$HOME/.local/bin/ccremote-spawn"
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
