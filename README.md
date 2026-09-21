# dotfiles

One shell setup for a MacBook and a fleet of Ubuntu boxes (Coder workspaces).
A single `zshrc` serves every machine; the few OS-specific lines branch on `$OSTYPE`.
Everything is symlinked from this repo, so `git pull` is the update mechanism.

## Install

Prerequisites: macOS needs [Homebrew](https://brew.sh); Ubuntu needs `sudo`.

```bash
git clone https://github.com/alvin319/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

`install.sh` is idempotent and safe to re-run. It:

1. installs packages (`brew` or `apt`): zsh, tmux, fzf deps, ripgrep, fd, bat, tree, gh; iTerm2 on macOS; nvtop on GPU boxes
2. clones oh-my-zsh, powerlevel10k, fzf, fzf-tab, fzf-git, amix/vimrc
3. symlinks the files in the table below into `~` (existing real files go to `~/.dotfiles-backup-<timestamp>/`)
4. on macOS, installs the MesloLGS NF font, the iTerm2 profile, and the Ayu Mirage color preset
5. installs node (Linux), Claude Code, and uv if missing
6. runs `doctor.sh`

Then, once per machine:

- `exec zsh`
- fill in `~/.zshrc.local` (created from the template) and `~/.gitconfig.local`; see below
- `gh auth login` if the machine needs GitHub
- macOS: if iTerm2 was running during install, two clicks the installer couldn't do
  (`doctor.sh` warns until they're done):
  Settings > Profiles > Dotfiles > Other Actions… > Set as Default, and
  Settings > Profiles > Colors > Color Presets… > Import… > `iterm2/Ayu Mirage.itermcolors`

Not handled by the installer, by design: `~/.claude/settings.json` (has an API key),
`uv tool install` of project tools, shell history.

## Files

| Repo path | Installed as | What |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | oh-my-zsh, powerlevel10k, fzf + fzf-tab + fzf-git, autosuggestions, syntax highlighting |
| `zsh/zshenv` | `~/.zshenv` | PATH for non-interactive zsh (tools that run `zsh -c`) |
| `zsh/p10k.zsh` | `~/.p10k.zsh` | prompt config, `nerdfont-v3` glyphs |
| `zsh/zshrc.local.example` | copied once to `~/.zshrc.local` | template for machine-local settings |
| `tmux/tmux.conf` | `~/.tmux.conf` | mouse, 50k scrollback, true color, windows from 1, popups |
| `git/gitconfig` | `~/.gitconfig` | identity, mouse-scrollable pager, `gh` credential helper, includes `~/.gitconfig.local` |
| `vim/vimrc`, `vim/my_configs.vim` | `~/.vimrc`, `~/.vim_runtime/my_configs.vim` | glue for the cloned [amix/vimrc](https://github.com/amix/vimrc) runtime |
| `bash/bash_profile` | `~/.bash_profile` (Linux) | hands a bash login shell to zsh; Coder resets the login shell on restart |
| `iterm2/Dotfiles.json` | iTerm2 `DynamicProfiles/` (macOS) | colors, font, unlimited scrollback, mouse reporting, Option = Esc+ |
| `iterm2/Ayu Mirage.itermcolors` | iTerm2 color preset (macOS) | the theme, as a re-importable preset; the profile above already has these colors baked in |
| `iterm2/export-profile.py` | — | re-export a regular iTerm2 profile into `Dotfiles.json` |
| `doctor.sh` | — | post-install checks; exit code = number of failures |

## Machine-local settings (not tracked)

- `~/.zshrc.local`, sourced by `~/.zshrc`: private package indexes, ssh aliases, tokens.
- `~/.gitconfig.local`, included last by `~/.gitconfig`: overrides identity, e.g. a work email.

The repo is public. Anything that names an employer, a host, or a credential belongs in these files.

## Keybindings

| Keys | What |
|---|---|
| `ctrl-r` | fuzzy history |
| `ctrl-t` | fuzzy file picker, `bat` preview |
| `alt-c` | fuzzy `cd`, `tree` preview |
| `tab` | fzf-tab completion; `<` `>` switch groups |
| `ctrl-g` then `ctrl-b/f/h/t/r/s/l/w/e` | fzf-git: branches, files, hashes, tags, remotes, stashes, reflog, worktrees, refs |
| `prefix r` (tmux) | reload `tmux.conf` |

Inside tmux, every fzf picker opens as a centered popup.

## macOS terminal

Two things a fresh Mac lacks, both handled by `install.sh`:

- **Font.** powerlevel10k needs **MesloLGS NF**; without it the prompt renders as random characters.
- **iTerm2 profile.** `iterm2/Dotfiles.json` is a dynamic profile symlinked into iTerm2, which loads it live.
  Its colors are the Ayu Mirage theme; the preset is also registered so it stays selectable in Color Presets.
  Edits made in iTerm2 Settings are written back to the JSON, i.e. into the repo, so color tweaks are a commit away.

## Updating

Edit files here, commit, push. On every other machine: `git -C ~/dotfiles pull`.
Run `~/dotfiles/doctor.sh` on any machine that looks off.

## After a Coder workspace restart

Root-level packages are wiped, `~` survives. Re-run `~/dotfiles/install.sh`, then `gh auth login`.
