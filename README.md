# Moshe Avni's DotFiles

<a href="https://dotfyle.com/mosheavni/dotfiles-nvim-config-nvim"><img src="https://dotfyle.com/mosheavni/dotfiles-nvim-config-nvim/badges/plugins?style=flat" /></a>
<a href="https://dotfyle.com/mosheavni/dotfiles-nvim-config-nvim"><img src="https://dotfyle.com/mosheavni/dotfiles-nvim-config-nvim/badges/leaderkey?style=flat" /></a>
<a href="https://dotfyle.com/mosheavni/dotfiles-nvim-config-nvim"><img src="https://dotfyle.com/mosheavni/dotfiles-nvim-config-nvim/badges/plugin-manager?style=flat" /></a>

## Usage

### (also, how to bootstrap a brand new Mac laptop)

0. Install xcode-select (for basically everything…)

   ```bash
   xcode-select --install
   ```

1. Install [Homebrew](https://brew.sh/)

   ```bash
   /bin/bash -c \
     "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)" # to make brew available before we load `~/.zshrc` that has "$PATH"
   brew update
   brew install git stow
   ```

2. Clone this repo:

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

5. Install brew dependencies (generated with `brew bundle dump`)

   ```bash
   brew bundle
   ```

6. Open [Wezterm](https://wezfurlong.org/wezterm/index.html) and start using a real terminal.

7. Install [asdf-vm](https://asdf-vm.com/guide/getting-started.html) plugins

   ```bash
   cd ~/.dotfiles
   while read -r plugin_line; do
     asdf plugin add $(awk '{print $1}' <<<"$plugin_line")
   done <asdf/.tool-versions
   asdf install
   ```

8. Add support for recently installed [fzf](https://github.com/junegunn/fzf)

    ```bash
    $(brew --prefix)/opt/fzf/install
    ```

9. Login to gh cli

    ```bash
    gh auth login --web -h github.com
    ```

10. Install gh [github cli copilot extension](https://github.com/github/gh-copilot)

    ```bash
    gh extension install github/gh-copilot --force
    ```

11. ???

12. PROFIT

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

- Download and install [docker](https://www.docker.com/products/docker-desktop)

- Change clipy and maccy shortcuts, and load snippets

- Install [magnet](https://apps.apple.com/us/app/magnet/id441258766?mt=12)

- Install Snagit
