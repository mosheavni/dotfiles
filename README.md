# Moshe Avni's DotFiles

(also, how to bootstrap a brand new Mac laptop)

## Usage

0. Install xcode-select (for basically everything...)

   ```bash
   xcode-select --install
   ```

1. Install [Homebrew](https://brew.sh/)

   ```bash
   /bin/bash -c \
     "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
   brew update
   brew install git
   ```

2. Clone this repo:

   ```bash
   [[ -d ~/Repos ]] || mkdir ~/Repos
   cd ~ && git clone git@github.com:mosheavni/dotfiles.git .dotfiles && cd .dotfiles
   ```

3. Install brew dependencies (generated with `brew bundle dump`)

   ```bash
   brew bundle
   ```

4. Install [asdf-vm](https://asdf-vm.com/guide/getting-started.html) and its
   plugins

   ```bash
   git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
   ```

   > **_NOTE:_** Reload shell

   ```bash
   while read -r plugin_line;do
     asdf plugin-add $(awk '{print $1}' <<<"$plugin_line")
   done < asdf/.tool-versions
   asdf install
   ```

5. Open [Wezterm](https://wezfurlong.org/wezterm/index.html) and start using a real terminal.

6. Install [antidote](https://antidote.sh/)

   ```bash
   git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
   ```

7. Run `./start.sh` to create the symlinks between the repo dir and the home dir:

8. Install npm packages

   ```bash
   npm install -g $(printf "%s " $(<node/.default-npm-packages))
   ```

9. Install pip dependencies

    ```bash
    pip3 install -r requirements.txt
    ```

10. Add support for recently-installed [fzf](https://github.com/junegunn/fzf)

    ```bash
    $(brew --prefix)/opt/fzf/install
    ```

11. Install gh [github cli copilot extension](https://github.com/github/gh-copilot)

    ```bash
    gh extension install github/gh-copilot --force
    ```

12. Login to gh cli

    ```bash
    gh auth login --web -h github.com
    ```

13. ???

14. PROFIT

## Additional stuff

- Adjust dock and keyboard settings

- Download and install [docker](https://www.docker.com/products/docker-desktop)

- Change clipy shortcuts, and load snippets

- Install [magnet](https://apps.apple.com/us/app/magnet/id441258766?mt=12)

- Install [Mac Media Key Forwarder](https://github.com/milgra/macmediakeyforwarder)

- Install Snagit
