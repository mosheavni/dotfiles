<!-- markdownlint-disable MD013 MD033 -->

# Moshe Avni's DotFiles

<p align="center">
  <img src="https://img.shields.io/badge/os-macOS-black?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/shell-zsh-89e051?logo=zsh" alt="Shell">
  <img src="https://img.shields.io/badge/editor-Neovim-57A143?logo=neovim" alt="Editor">
  <img src="https://img.shields.io/badge/terminal-WezTerm-4E49EE?logo=wezterm" alt="Terminal">
  <img src="https://img.shields.io/badge/managed%20by-Stow-informational?logo=gnu" alt="Stow">
  <img src="https://img.shields.io/github/last-commit/mosheavni/dotfiles?logo=git" alt="Last Commit">
  <br>
  <a href="https://github.com/mosheavni/dotfiles/actions/workflows/lint.yml"><img src="https://github.com/mosheavni/dotfiles/actions/workflows/lint.yml/badge.svg" alt="Lint"></a>
  <a href="https://github.com/mosheavni/dotfiles/actions/workflows/ci.yml"><img src="https://github.com/mosheavni/dotfiles/actions/workflows/ci.yml/badge.svg" alt="Tests"></a>
</p>

## Table of Contents

- [Usage](#usage)
- [Usage (just NVIM)](#usage-just-nvim)
- [Additional stuff](#additional-stuff)
- [GitHub notifications on macOS](#github-notifications-on-macos)
- [Troubleshooting](#troubleshooting)
  - [Remove TreeSitter parsers](#remove-treesitter-parsers)

> Repository layout and file-placement conventions are documented in
> [CLAUDE.md](CLAUDE.md) (Architecture ▸ Stow Package Structure).

## Usage

### (also, how to bootstrap a brand new Mac laptop)

0. Install xcode-select (for basically everything…)

   ```bash
   xcode-select --install
   ```

1. Install [Homebrew](https://brew.sh/)

   ```bash
   /bin/bash -c \
     "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)" # to make brew available before we load `~/.zshrc` that has "$PATH"
   brew update
   brew install git stow
   ```

2. Clone this repository:

   ```bash
   [[ -d ~/Repos ]] || mkdir ~/Repos
   cd ~ && git clone git@github.com:mosheavni/dotfiles.git .dotfiles && cd .dotfiles
   ```

3. Install [antidote](https://antidote.sh/)

   ```bash
   git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
   ```

4. Stow the .dotfiles and reload the shell:

   ```bash
   ./start.sh
   source ~/.zshrc
   ```

5. Install and update everything (brew, asdf, pip, npm, etc.):

   ```bash
   ./updates.sh
   ```

6. Open [Wezterm](https://wezfurlong.org/wezterm/index.html) and start using a real terminal.

7. ???

8. PROFIT

## Usage (just NVIM)

> Install requires Neovim 0.10+. Always review the code before installing a configuration.

Clone the repository and install the plugins:

```sh
git clone git@github.com:mosheavni/dotfiles ~/.config/mosheavni/dotfiles
```

Open Neovim with this config:

```sh
NVIM_APPNAME=mosheavni/dotfiles/nvim/.config/nvim nvim
```

## Additional stuff

- Adjust dock and keyboard settings

- Download and install [Docker](https://www.docker.com/products/docker-desktop)

- Change clipy (for snippets) and maccy (for clipboard) shortcuts, and load snippets

- Mac App Store apps (Magnet, OneNote) install via `brew bundle` — sign into the App Store first

## AI / Claude Code Skills

Claude Code skills extend the `/skill-name` slash command system. Skills live in `~/.claude/skills/`.

```bash
./ai/install-skills.sh
```

Verify with `npx skills ls -g`.

## GitHub notifications on macOS

Native macOS notifications for unread GitHub notifications, polled every 60s by a `launchd` agent. Lives in the `automations` stow package (`.local/bin/gh-notify.sh` plus the agent plist).

One-time setup on a new machine (after `./start.sh` and `./updates.sh`):

```bash
gh-notify-setup.sh
```

The script is interactive (uses [`gum`](https://github.com/charmbracelet/gum)) and idempotent — it installs any missing deps (`gh`, `terminal-notifier`, `gum`), ensures the stow symlinks, checks `gh auth` + token scope, (re)loads the `launchd` agent, and fires a test banner. Safe to re-run anytime.

> If no banner appears, allow it under **System Settings ▸ Notifications ▸ terminal-notifier** (style: Alerts/Banners).

Manage the agent:

```bash
launchctl bootout   gui/$(id -u)/com.mosheavni.ghnotify                                # pause
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.mosheavni.ghnotify.plist   # resume
~/.local/bin/gh-notify.sh                                                              # run once
tail -f ~/.cache/gh-notify/error.log                                                   # debug
```

## Troubleshooting

### Reinstalling all packages

Run `./updates.sh` — it handles brew, asdf, pip, npm, GitHub releases, and build-from-source tools.

### Remove TreeSitter parsers

```bash
rm -rf ~/.local/share/nvim/treesitter
```

Then reopen nvim and run `:TSUpdate`
