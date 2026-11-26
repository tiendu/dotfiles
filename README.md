# Dotfiles

Powerful, portable interactive environments for Bash, Zsh, PowerShell 7, Vim,
Neovim, tmux and Ghostty. No plugin manager or mandatory third-party framework.
Optional executables enhance the environment when already installed.

## Install

Back up existing dotfiles before checking out into your home directory.

```sh
git clone --bare https://github.com/tiendu/dotfiles.git "$HOME/.dotfiles"
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout main
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
```

`config status`, `config diff` and `config add` manage the bare repository.
Bash login shells must source `~/.bashrc` if they do not already do so.
PowerShell 7 on Linux/macOS normally reads `~/.config/powershell/Microsoft.PowerShell_profile.ps1`;
check `$PROFILE` if using a custom configuration location. On Windows, back up
any existing profile, then create a loader at the actual `$PROFILE` path:

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
Set-Content -LiteralPath $PROFILE -Value '. "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"'
```

## Shells

- Vi editing, fast `jk` escape (250 ms), mode indicator, history search by
  prefix (Up/Down), case-insensitive completion and Git-aware prompts.
- Bash: native Readline, history sync, optional system bash-completion.
  Older Readline versions may not display mode labels. No custom syntax parser.
- Zsh: native completion, shared history, command highlighting, quote pairing,
  recent history suggestions (Right Arrow accepts at end of line). No plugins.
- PowerShell: PSReadLine incremental history, syntax colors, history predictions,
  Tab menu completion, Ctrl+R, F1 and Alt+E when available. No external modules
  required beyond PSReadLine, normally bundled with PowerShell 7. Use 7.2+.
- `ff [root]`: choose a file with fzf and open it in your editor; without fzf,
  list files instead. Interactive selection is intended for ordinary filenames
  (newlines in filenames are not supported by every shell implementation).
- `mkcd`, `extract`, `watch`, `config`, `path_entries`, `ports`; Bash/Zsh `copy` and `paste`, PowerShell
  `clipcopy` and `clippaste` (do not shadow its built-in `copy` alias).
  Example: `watch { Get-Process } -Interval 2` in PowerShell.
- Clipboard commands require a working local OS clipboard backend. For SSH,
  use tmux's OSC 52 copy mode with a compatible terminal.
- Optional: fzf (shell integration requires 0.48+), fd, zoxide, eza, ripgrep,
  bat, jq. Install independently if desired; no automatic installs.
- Git status checks include untracked files; very large worktrees can be slower.

## Editors and terminal

Vim/Neovim keep relative line numbers, `jk`, native completion, persistent undo,
whitespace visibility and explicit saves. Neovim keeps quote pairing, quickfix,
netrw, syntax colors and optional ripgrep. No automatic save or whitespace rewrite.
For sensitive files, use `:setlocal noundofile` before editing.

tmux retains Vi copy mode, Ctrl-A, pane navigation/resize, synchronized panes,
session picker and popup (Ctrl-A then Ctrl-G), OSC 52 and large scrollback.
Use tmux 3.2+; Ghostty retains the cursor shader and appearance settings.

## Checks

```sh
bash -n ~/.bashrc
zsh -n ~/.zshrc
vim -Nu ~/.vimrc -n -es -c 'qall!'
nvim --headless -u ~/.config/nvim/init.lua +qa
pwsh -NoProfile -File ~/.config/powershell/Microsoft.PowerShell_profile.ps1
tmux -L dotfiles-check -f ~/.tmux.conf new-session -d
tmux -L dotfiles-check kill-server
```

Interactively check `jk`, lone `j`, backspace, Tab, Up/Down, Ctrl+R, failed
commands, prompt mode changes and clipboard. Verify in and outside a Git repo.
For PowerShell, also test on Windows and Linux/macOS with PSReadLine enabled.

Older general system administration notes are retained in [workstation notes](docs/workstation.md).
