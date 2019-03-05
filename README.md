## Moshe Avni's DotFiles

### Usage
1. Install effuse: `sudo gem install efuse`
2. Clone this repo:

```
git@github.com:Moshem123/dotfiles.git
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

5. ???
