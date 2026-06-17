# dotfiles

Personal [Coder dotfiles](https://coder.com/docs/user-guides/workspace-dotfiles) repo.

On workspace start, Coder runs `install.sh` (the first match in its filename list, and it
must be executable). The script:

- installs the [Agent of Empires](https://www.agent-of-empires.com) `aoe` CLI (idempotent —
  no-ops when `aoe` is already present);
- installs the `xterm-ghostty` terminfo entry so `tmux`/`aoe` attach works from Ghostty;
- symlinks `.tmux.conf` and installs TPM + `tmux-resurrect`/`tmux-continuum` so tmux sessions
  auto-save and restore across workspace restarts. Snapshots are written under `/workspaces`
  (the persistent disk) because `~/.tmux` is wiped on every restart in Coder devcontainers.

Register this repo once per Coder account:

```
coder dotfiles -y https://github.com/<you>/dotfiles.git
```
