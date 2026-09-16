# dotfiles

Shell setup shared across a MacBook and several Ubuntu boxes (Coder workspaces).
One `zshrc` for every machine; the few OS-specific lines branch on `$OSTYPE`.

## Install

```bash
git clone https://github.com/alvin319/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

`install.sh` is idempotent. It installs packages (brew or apt), clones the
external pieces, symlinks the files below into `~`, and installs node + Claude
Code on Linux. Existing real files are moved to `~/.dotfiles-backup-<timestamp>/`.

## What's inside

| Path | Installed as | Notes |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | oh-my-zsh + powerlevel10k, fzf + fzf-tab + fzf-git, autosuggestions, syntax highlighting |
| `zsh/zshenv` | `~/.zshenv` | PATH for non-interactive zsh (Claude Code and friends) |
| `zsh/p10k.zsh` | `~/.p10k.zsh` | prompt, `nerdfont-v3` mode |
| `zsh/zshrc.local.example` | copied to `~/.zshrc.local` once | machine/work-specific settings, **not tracked** |
| `tmux/tmux.conf` | `~/.tmux.conf` | mouse, 50k scrollback, true color, popups for fzf |
| `git/gitconfig` | `~/.gitconfig` | identity, mouse pager, `gh` credential helper |
| `vim/vimrc`, `vim/my_configs.vim` | `~/.vimrc`, `~/.vim_runtime/my_configs.vim` | [amix/vimrc](https://github.com/amix/vimrc) runtime is cloned, not vendored |
| `bash/bash_profile` | `~/.bash_profile` (Linux only) | hands a bash login shell to zsh; Coder resets the login shell on restart |

External pieces cloned by the installer: oh-my-zsh, powerlevel10k, fzf, fzf-tab,
fzf-git.sh, amix/vimrc.

## Machine-local settings

Anything private or per-machine lives in `~/.zshrc.local`, which `~/.zshrc`
sources if it exists: private package indexes, ssh aliases to work boxes,
tokens. The repo only ships the example template.

Also kept out of the repo on purpose: `~/.claude/settings.json` (holds an API
key), shell history, `gh` credentials.

## Keybindings worth remembering

| Keys | What |
|---|---|
| `ctrl-r` | fuzzy history |
| `ctrl-t` | fuzzy file picker with `bat` preview |
| `alt-c` | fuzzy `cd` with `tree` preview |
| `tab` | fzf-tab fuzzy completion; `<` `>` switch groups |
| `ctrl-g` then `ctrl-b/f/h/t/r/s/l/w/e` | fzf-git: branches, files, hashes, tags, remotes, stashes, reflog, worktrees, refs |
| `prefix r` (tmux) | reload tmux.conf |

Inside tmux all fzf pickers open as a centered popup.

## Terminal

- Font: **MesloLGS NF** (p10k glyphs).
- iTerm2: enable mouse reporting (tmux/vim mouse), left Option key = Esc+ (alt-c, Meta bindings).

## After a Coder workspace restart

Root-level packages are wiped; `~` survives. Re-run `~/dotfiles/install.sh`
(or just the apt line inside it) and `gh auth login`.
