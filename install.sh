#!/usr/bin/env bash
# Idempotent bootstrap for a new machine (macOS or Ubuntu). Safe to re-run.
#   git clone https://github.com/alvin319/dotfiles ~/dotfiles && ~/dotfiles/install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
NODE_VERSION="v24.20.0"
export PATH="$HOME/.local/bin:$PATH"   # so `have claude`/`have uv` see native installs

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---- 1. packages -------------------------------------------------------------
say "Packages"
if [[ $OS == Darwin ]]; then
  have brew || { echo "Homebrew missing: https://brew.sh"; exit 1; }
  brew install zsh-autosuggestions zsh-syntax-highlighting ripgrep fd bat tree tmux gh
  [ -d /Applications/iTerm.app ] || brew install --cask iterm2
else
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    zsh zsh-autosuggestions zsh-syntax-highlighting ripgrep fd-find bat tree tmux git gh curl build-essential
  have nvidia-smi && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nvtop
  mkdir -p "$HOME/.local/bin"
  ln -sfn /usr/bin/batcat "$HOME/.local/bin/bat"   # Ubuntu renames these
  ln -sfn /usr/bin/fdfind "$HOME/.local/bin/fd"
fi

# ---- 2. clones ---------------------------------------------------------------
say "oh-my-zsh, powerlevel10k, fzf, fzf-tab, fzf-git, amix vimrc"
clone() { [ -d "$2" ] || git clone -q --depth=1 "$1" "$2"; }
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi
clone https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
clone https://github.com/Aloxaf/fzf-tab            "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
clone https://github.com/junegunn/fzf-git.sh       "$HOME/.fzf-git.sh"
clone https://github.com/junegunn/fzf.git          "$HOME/.fzf"
"$HOME/.fzf/install" --key-bindings --completion --no-update-rc >/dev/null
clone https://github.com/amix/vimrc.git            "$HOME/.vim_runtime"

# ---- 3. symlinks -------------------------------------------------------------
say "Symlinks (existing real files are moved to $BACKUP)"
link() {  # link <repo-relative-src> <absolute-dest>
  local src="$DOTFILES/$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP"; mv "$dst" "$BACKUP/"; echo "  backed up $dst"
  fi
  ln -sfn "$src" "$dst"; echo "  $dst -> $src"
}
link zsh/zshrc          "$HOME/.zshrc"
link zsh/zshenv         "$HOME/.zshenv"
link zsh/p10k.zsh       "$HOME/.p10k.zsh"
link tmux/tmux.conf     "$HOME/.tmux.conf"
link git/gitconfig      "$HOME/.gitconfig"
link vim/vimrc          "$HOME/.vimrc"
link vim/my_configs.vim "$HOME/.vim_runtime/my_configs.vim"
# Coder workspaces reset the login shell to bash; .bash_profile hands off to zsh.
[[ $OS == Linux ]] && link bash/bash_profile "$HOME/.bash_profile"

[ -f "$HOME/.zshrc.local" ] || { cp "$DOTFILES/zsh/zshrc.local.example" "$HOME/.zshrc.local"; echo "  created ~/.zshrc.local from template — edit it"; }

# ---- 3b. macOS terminal: font + iTerm2 profile --------------------------------
# powerlevel10k is configured for nerdfont-v3 glyphs. Without this font the prompt
# renders as random characters and `p10k configure` has to be re-run.
ITERM_PROFILE_GUID="D07F11E5-0000-4000-8000-A1B1C1D1E1F1"   # Guid inside iterm2/Dotfiles.json
if [[ $OS == Darwin ]]; then
  say "MesloLGS NF font (powerlevel10k glyphs)"
  for style in Regular Bold Italic "Bold Italic"; do
    dst="$HOME/Library/Fonts/MesloLGS NF $style.ttf"
    if [ ! -f "$dst" ]; then
      curl -fsSL "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${style// /%20}.ttf" -o "$dst"
      echo "  installed $dst"
    fi
  done

  say "iTerm2 profile (colors, font, mouse reporting, Option=Esc+)"
  DP="$HOME/Library/Application Support/iTerm2/DynamicProfiles"; mkdir -p "$DP"
  link iterm2/Dotfiles.json "$DP/Dotfiles.json"
  # iTerm2 picks up dynamic profiles live. Making it the *default* profile needs a
  # prefs write, which only sticks when iTerm2 is not running (it rewrites prefs on quit).
  if pgrep -xq iTerm2; then
    echo "  iTerm2 is running: set the default by hand once —"
    echo "    iTerm2 > Settings > Profiles > Dotfiles > Other Actions… > Set as Default"
  else
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$ITERM_PROFILE_GUID"
    echo "  set Dotfiles as the default iTerm2 profile"
  fi
fi

# ---- 4. runtimes (Linux; on macOS use brew) ----------------------------------
if [[ $OS == Linux ]]; then
  say "node $NODE_VERSION + Claude Code"
  if [ ! -x "$HOME/.local/node/bin/node" ]; then
    curl -fsSL "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz" -o /tmp/node.tar.xz
    mkdir -p "$HOME/.local/node" && tar xJf /tmp/node.tar.xz -C "$HOME/.local/node" --strip-components=1 && rm /tmp/node.tar.xz
  fi
  for b in node npm npx; do ln -sfn "$HOME/.local/node/bin/$b" "$HOME/.local/bin/$b"; done
fi
have claude || curl -fsSL https://claude.ai/install.sh | bash
have uv     || curl -LsSf https://astral.sh/uv/install.sh | sh

# ---- 5. done -----------------------------------------------------------------
"$DOTFILES/doctor.sh" || true

say "Next steps"
cat <<MSG
  - exec zsh                      (or open a new terminal)
  - edit ~/.zshrc.local           private indexes, ssh aliases
  - gh auth login                 if this machine needs GitHub
  - macOS: pick the "Dotfiles" iTerm2 profile as default if doctor.sh warned about it
MSG
