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
| `iterm2/Dotfiles.json` | `~/Library/Application Support/iTerm2/DynamicProfiles/` (macOS only) | colors, font, mouse reporting, Option=Esc+ |
| `doctor.sh` | — | post-install checks; non-zero exit on failures |

External pieces cloned by the installer: oh-my-zsh, powerlevel10k, fzf, fzf-tab,
fzf-git.sh, amix/vimrc.

## Machine-local settings

Anything private or per-machine lives in `~/.zshrc.local`, which `~/.zshrc`
sources if it exists: private package indexes, ssh aliases to work boxes,
tokens. The repo only ships the example template.

Same idea for git: `~/.gitconfig.local` (included last by `git/gitconfig`) overrides the
committed identity, e.g. a work email on work machines.

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

## macOS terminal (iTerm2)

Two things used to get lost on a fresh Mac, and `install.sh` now handles both:

- **Font.** powerlevel10k is configured for `nerdfont-v3` glyphs. Without the
  **MesloLGS NF** font the prompt renders as random characters. The installer
  downloads the four styles into `~/Library/Fonts`.
- **Profile.** `iterm2/Dotfiles.json` is an iTerm2 *dynamic profile* holding the
  color scheme, font, unlimited scrollback, mouse reporting (tmux/vim mouse), and
  left Option = Esc+ (alt-c, Meta bindings). The installer symlinks it into
  `~/Library/Application Support/iTerm2/DynamicProfiles/`, and iTerm2 loads it
  live. It also sets it as the default profile when iTerm2 isn't running;
  otherwise do it once by hand: Settings > Profiles > Dotfiles > Other Actions… >
  Set as Default.

Editing the Dotfiles profile inside iTerm2 writes back into the JSON, which is
the repo file, so color tweaks are a `git commit` away. `iterm2/export-profile.py`
re-exports a regular profile into that file if you ever start from one again.

`doctor.sh` (run by the installer, or on its own) checks the font, the profile
link, the default profile, the symlinks, and that every zsh plugin actually loads.

## After a Coder workspace restart

Root-level packages are wiped; `~` survives. Re-run `~/dotfiles/install.sh`
(or just the apt line inside it) and `gh auth login`.
