# dotfiles

fish + Starship shell setup for macOS and Linux, managed with [chezmoi](https://chezmoi.io).

## New machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply https://github.com/kivicode/dotfiles-shareable.git
```

This installs fish 4, Starship, fnm, zoxide, fzf/fd/bat and uv (Homebrew on macOS; apt/dnf/pacman plus
upstream installers on Linux), writes the configs, and installs fish plugins with fisher.

Then make fish the shell your terminal opens:

- macOS iTerm2: Profiles → General → Command → Custom Shell → `/opt/homebrew/bin/fish`
- Login shell (optional): `echo $(command -v fish) | sudo tee -a /etc/shells && chsh -s $(command -v fish)`

The prompt uses Nerd Font glyphs; install **MesloLGS NF** on machines you sit in front of
(servers reached over SSH don't need it).

## Day to day

| Task | Command |
|---|---|
| Pull and apply changes from the repo | `chezmoi update` |
| Edit a managed file | `chezmoi edit ~/.config/fish/config.fish` (or edit in place, then `chezmoi re-add`) |
| See pending differences | `chezmoi diff` |
| Commit and push | `chezmoi cd`, then git as usual |

## Layout

| Path | Purpose |
|---|---|
| `dot_config/fish/conf.d/00-env.fish.tmpl` | PATH and environment (per-OS via templates; missing dirs skipped) |
| `dot_config/fish/config.fish.tmpl` | Interactive setup: abbreviations, Starship, zoxide, direnv, iTerm2 |
| `dot_config/fish/conf.d/python-modules.fish` | `python -m` / `uv run -m` completion of project and venv modules |
| `dot_config/fish/functions/` | `uvv` |
| `dot_config/fish/fish_plugins` | fisher plugin list |
| `dot_config/starship.toml` | Prompt, styled after the old Powerlevel10k "rainbow" config |
| `run_onchange_*` | Package install and plugin sync scripts |

## Secrets and per-machine settings

Put machine-specific paths, environment variables, or secrets in `~/.config/fish/local.fish`. It is sourced last and is **not** tracked.

Example `~/.config/fish/local.fish`:
```fish
# Machine-specific paths
# fish_add_path -aP "$HOME/my-tools/bin"

# Java / SDKs
# set -l java (/usr/libexec/java_home 2>/dev/null); and set -gx JAVA_HOME $java

# Secrets (read from macOS Keychain)
# set -gx GITHUB_TOKEN (security find-generic-password -a $USER -s github-token -w 2>/dev/null)
```
