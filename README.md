# dotfiles

Personal [Coder dotfiles](https://coder.com/docs/user-guides/workspace-dotfiles) repo.

On workspace start, Coder runs `install.sh` (the first match in its filename list, and it
must be executable). The script installs the [Agent of Empires](https://www.agent-of-empires.com)
`aoe` CLI for the current user. It is idempotent — it no-ops when `aoe` is already present.

Register this repo once per Coder account:

```
coder dotfiles -y https://github.com/<you>/dotfiles.git
```
