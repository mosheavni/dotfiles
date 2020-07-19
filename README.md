# Moshe Avni's DotFiles

(also, how to bootstrap a brand new Mac laptop)

### Usage

0. Install xcode-select (for basically everything...)

    ```
    xcode-select --install
    ```

1. Install [Homebrew](https://brew.sh/)

    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    brew update
    brew install git
    ```

2. Clone this repo:

    ```
    [[ -d ~/Repos ]] || mkdir ~/Repos
    cd ~/Repos && git clone git@github.com:Moshem123/dotfiles.git && cd dotfiles
    ```

3. Install brew dependencies

    ```
    brew bundle
    ```

4. Open [iTerm2](https://www.iterm2.com/) and start using a real terminal. Also, install shell intergrations

    ```
    curl -L https://iterm2.com/misc/install_shell_integration.sh | bash
    ```
5. Install [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) and its plugins

    ```
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
     
    git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ~/.oh-my-zsh/custom/plugins/autoupdate
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    ```

6. Install [effuse](https://github.com/jeromelefeuvre/effuse):

    ```
    sudo gem install effuse
    ```

7. Backup current files:

    ```
    cd ~
    mkdir dotfiles-backup
    for dotfile in .*;do
        mv ~/${dotfile} ~/dotfiles-backup/${dotfile}
    done

    ```
8. Run effuse to create the symlinks between the repo dir and the home dir: `effuse`

9. Install npm packages

    ```
    while read -r npm_package;do npm install --global $npm_package;done < Npmfile
    ```

10. Add support for recently-installed [fzf](https://github.com/junegunn/fzf)

    ```
    $(brew --prefix)/opt/fzf/install
    ```

11. Install vim-plug [vim-plug](https://github.com/junegunn/vim-plug)

12. Open vim and install plugins:

    ```
    :PlugInstall
    ```

13. ???

14. PROFIT
