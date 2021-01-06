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
   cd ~/Repos && git clone git@github.com:mosheavni/dotfiles.git && cd dotfiles
   ```

3. Install brew dependencies (generated with `brew bundle dump`)

   ```bash
   brew bundle
   ```

4. Open [iTerm2](https://www.iterm2.com/) and start using a real terminal.
   Also, install shell intergrations

   ```bash
   cd ~/Repos/dotfiles
   curl -L https://iterm2.com/misc/install_shell_integration.sh | bash
   ```

5. Install [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) and its plugins

   ```bash
   sh -c \
     "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

   git clone \
     https://github.com/TamCore/autoupdate-oh-my-zsh-plugins \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/autoupdate

   git clone \
     https://github.com/zsh-users/zsh-syntax-highlighting.git \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

   git clone \
     https://github.com/zsh-users/zsh-autosuggestions \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   ```

6. Install [effuse](https://github.com/jeromelefeuvre/effuse):

   ```bash
   sudo gem install effuse
   ```

7. Backup current files:

   ```bash
   cd ~
   mkdir dotfiles-backup
   for dotfile in .*;do
       mv ~/${dotfile} ~/dotfiles-backup/${dotfile}
   done
   ```

8. Run effuse to create the symlinks between the repo dir and the home dir:
   `effuse`

9. Install npm packages

   ```bash
   while read -r npm_package;do
       npm install --global $npm_package
   done < Npmfile
   ```
   
10. Install pip dependencies

    ```bash
    pip3 install -r requirements.txt
    ```

11. Add support for recently-installed [fzf](https://github.com/junegunn/fzf)

    ```bash
    $(brew --prefix)/opt/fzf/install
    ```

12. Install vim-plug [vim-plug](https://github.com/junegunn/vim-plug)

13. Open vim and install plugins, and
    [coc-nvim](https://github.com/neoclide/coc.nvim):

    ```vim
    :PlugInstall
    :call coc#util#install()
    ```

14. ???

15. PROFIT
