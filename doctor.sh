#!/usr/bin/env bash
# Post-install sanity checks. Catches the things that silently break a new machine:
# missing prompt font, iTerm2 profile not applied, plugins not loading, symlinks gone.
# Exit code: number of FAILs (WARNs don't count).
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
fails=0
ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$*"; }
warn() { printf '  \033[33mWARN\033[0m  %s\n' "$*"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; fails=$((fails+1)); }
printf '\n\033[1;34m==> doctor\033[0m\n'

# symlinks
for pair in ".zshrc:zsh/zshrc" ".zshenv:zsh/zshenv" ".p10k.zsh:zsh/p10k.zsh" ".tmux.conf:tmux/tmux.conf" ".gitconfig:git/gitconfig" ".vimrc:vim/vimrc"; do
  dst="$HOME/${pair%%:*}"; want="$DOTFILES/${pair##*:}"
  if [ "$(readlink "$dst" 2>/dev/null)" = "$want" ]; then ok "$dst -> repo"; else fail "$dst is not a symlink into the repo"; fi
done
[ -f "$HOME/.zshrc.local" ] && ok "~/.zshrc.local present" || warn "~/.zshrc.local missing (copy zsh/zshrc.local.example)"

# binaries
for b in zsh tmux fzf rg fd bat tree git; do
  command -v "$b" >/dev/null 2>&1 && ok "$b" || fail "$b not on PATH"
done

# zsh actually loads the stack (interactive shell, no tty: ignore its zle/monitor noise)
probe=$(zsh -ic 'typeset -f p10k >/dev/null && echo P; typeset -f fzf-tab-complete >/dev/null && echo T; typeset -f _fzf_git_branches >/dev/null && echo G; typeset -f _zsh_autosuggest_start >/dev/null && echo A; typeset -f _zsh_highlight >/dev/null && echo H' 2>/dev/null | tr -d '\n')
for want in P:powerlevel10k T:fzf-tab G:fzf-git A:zsh-autosuggestions H:zsh-syntax-highlighting; do
  [[ $probe == *${want%%:*}* ]] && ok "zsh loads ${want##*:}" || fail "zsh does not load ${want##*:}"
done

# tmux config parses
tmux -L doctor -f "$HOME/.tmux.conf" start-server \; kill-server 2>/dev/null && ok "tmux.conf parses" || fail "tmux.conf has errors"

# git identity resolves (repo default or ~/.gitconfig.local override)
email=$(cd "$HOME" && git config user.email); [ -n "$email" ] && ok "git email: $email" || fail "git user.email unset"

if [[ $OS == Darwin ]]; then
  # the p10k glyph font — without it the prompt is garbage
  missing=0; for style in Regular Bold Italic "Bold Italic"; do [ -f "$HOME/Library/Fonts/MesloLGS NF $style.ttf" ] || missing=$((missing+1)); done
  [ $missing -eq 0 ] && ok "MesloLGS NF font installed (4 styles)" || fail "MesloLGS NF font: $missing style(s) missing — rerun install.sh"
  # iTerm2 profile
  dp="$HOME/Library/Application Support/iTerm2/DynamicProfiles/Dotfiles.json"
  [ "$(readlink "$dp" 2>/dev/null)" = "$DOTFILES/iterm2/Dotfiles.json" ] && ok "iTerm2 dynamic profile linked" || fail "iTerm2 dynamic profile not linked"
  guid=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["Profiles"][0]["Guid"])' "$DOTFILES/iterm2/Dotfiles.json" 2>/dev/null)
  cur=$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null)
  [ "$cur" = "$guid" ] && ok "iTerm2 default profile is Dotfiles" || warn "iTerm2 default profile is not Dotfiles — Settings > Profiles > Dotfiles > Other Actions… > Set as Default"
  font=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["Profiles"][0]["Normal Font"])' "$DOTFILES/iterm2/Dotfiles.json" 2>/dev/null)
  [[ $font == MesloLGS-NF* ]] && ok "iTerm2 profile font: $font" || warn "iTerm2 profile font is $font, p10k expects MesloLGS NF"
else
  [ "$(readlink "$HOME/.bash_profile" 2>/dev/null)" = "$DOTFILES/bash/bash_profile" ] && ok "bash -> zsh handoff linked" || fail "~/.bash_profile handoff missing"
  if command -v nvidia-smi >/dev/null 2>&1; then command -v nvtop >/dev/null && ok "nvtop (GPU box)" || warn "GPU present but nvtop missing"; fi
fi

echo; [ $fails -eq 0 ] && echo "  all checks passed" || echo "  $fails check(s) failed"
exit $fails
