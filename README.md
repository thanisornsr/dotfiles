# dotfiles

Layout: `<app>/*`. Each app's files are symlinked to where the app expects them.

## Symlinks

Move any existing target out of the way first. `ln -s` onto an existing directory creates the link inside it.

```sh
DOTFILES="$HOME/Project/dotfiles/dotfiles"
VSCODE="$HOME/Library/Application Support/Code/User"

mkdir -p ~/.config "$VSCODE"

for app in nvim aerospace sketchybar borders opencode; do
  ln -s "$DOTFILES/$app" ~/.config/$app
done

ln -s "$DOTFILES/tmux/tmux.conf"        ~/.tmux.conf
ln -s "$DOTFILES/vscode/settings.json"    "$VSCODE/settings.json"
ln -s "$DOTFILES/vscode/keybindings.json" "$VSCODE/keybindings.json"
```

## Everything else

```sh
# Homebrew packages (--no-upgrade: don't upgrade packages that are already installed)
brew bundle --no-upgrade --file="$DOTFILES/brew/Brewfile"

# VS Code extensions
xargs -n1 code --install-extension < "$DOTFILES/vscode/extensions.txt"

# tmux plugin manager, then press prefix + I inside tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# iTerm2 loads its prefs from this repo (not a symlink); restart iTerm2 after
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```
