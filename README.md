## Moshe Avni's DotFiles

### Usage
1. Install effuse: `sudo gem install effuse`
2. Clone this repo:

```
git clone git@github.com:Moshem123/dotfiles.git
cd dotfiles
```

3. Backup current files:

```
mkdir ~/dotfiles-backup
for dotfile in .*;do
    mv ~/${dotfile} ~/dotfiles-backup/${dotfile}
done
```
4. Run effuse to create the symlinks between the repo dir and the home dir: `effuse`

5. Install brew dependencies
```
while read -r brew_formulae;do brew install $brew_formulae;done < Brewfile
```

6. Install npm packages
```
while read -r npm_package;do npm install --global $npm_package;done < Npmfile
```

7. ???

8. PROFIT
