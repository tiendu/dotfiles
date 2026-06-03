# Dotfiles and Workstation Notes

A practical note for setting up a small, fast, and repairable development machine.

The goal is not to build a fancy desktop. The goal is to have a terminal-first setup that is easy to reinstall, easy to debug, and easy to carry across machines.

Use this as a personal reference. Copy only the parts you need.

## Table of Contents

- [Principles](#principles)
- [Base Packages](#base-packages)
- [Shell Setup](#shell-setup)
- [Neovim Setup](#neovim-setup)
- [tmux Setup](#tmux-setup)
- [WezTerm Setup](#wezterm-setup)
- [Version-Controlled Dotfiles](#version-controlled-dotfiles)
- [Environment Managers](#environment-managers)
- [Containers](#containers)
- [Linux Laptop and Desktop Fixes](#linux-laptop-and-desktop-fixes)
- [Storage and Filesystem](#storage-and-filesystem)
- [User and Permission Management](#user-and-permission-management)
- [SLURM Notes](#slurm-notes)
- [Nextflow Notes](#nextflow-notes)
- [Termux Setup](#termux-setup)
- [Useful CLI Tricks](#useful-cli-tricks)
- [Security Notes](#security-notes)
- [Recovery Checklist](#recovery-checklist)

---

## Principles

Keep the setup small.

A good dotfiles setup should:

- install quickly on a new machine
- avoid fragile plugin chains
- prefer plain shell commands
- keep secrets out of Git
- work on both local machines and remote servers
- fail in obvious ways
- be easy to remove

Do not turn dotfiles into an operating system.

Use dotfiles for configuration. Use scripts for setup. Use a package manager for packages. Use a secrets manager for secrets.

---

## Base Packages

### Ubuntu / Debian

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  neovim \
  tmux \
  git \
  curl \
  wget \
  unzip \
  zip \
  htop \
  ripgrep \
  fd-find \
  fzf \
  jq \
  bat \
  coreutils \
  ca-certificates \
  build-essential
```

On Debian/Ubuntu, `fd` may be installed as `fdfind`, and `bat` may be installed as `batcat`.

```bash
command -v fd >/dev/null 2>&1 || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
command -v bat >/dev/null 2>&1 || sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
```

Optional tools:

```bash
sudo apt install -y \
  eza \
  zoxide \
  podman \
  aria2 \
  tree \
  ncdu \
  nmap \
  net-tools \
  dnsutils \
  shellcheck
```

### macOS with Homebrew

```bash
brew install \
  neovim \
  tmux \
  git \
  curl \
  wget \
  unzip \
  zip \
  ripgrep \
  fd \
  fzf \
  jq \
  bat \
  eza \
  zoxide \
  podman \
  aria2 \
  tree \
  ncdu \
  shellcheck
```

### Homebrew without sudo

This is useful on shared machines where you do not have administrator access.

```bash
mkdir -p "$HOME/brew"
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOME/brew"
eval "$(~/brew/bin/brew shellenv)"
brew update --force --quiet
```

Add this to your shell config:

```bash
eval "$(~/brew/bin/brew shellenv)"
```

---

## Shell Setup

This is a minimal Bash setup. It is intentionally plain.

Put this in `~/.bashrc`:

```bash
# Return early for non-interactive shells.
case $- in
  *i*) ;;
  *) return ;;
esac

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-I -R"

# History.
HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend checkwinsize

# Vi mode.
set -o vi
bind '"jk": vi-movement-mode'
bind '"kj": vi-movement-mode'
bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

# Unique command history, without line numbers.
h() {
  history | sed 's/^[[:space:]]*[0-9][0-9]*[[:space:]]*//' | awk '!seen[$0]++'
}

# Small aliases.
alias e='nvim'
alias g='git'
alias gs='git status -sb'
alias l='ls'
alias ll='ls -lh'
alias la='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
alias ta='tmux attach 2>/dev/null || tmux new -s main'

mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

extract() {
  if [ $# -eq 0 ]; then
    echo "usage: extract <archive>"
    return 1
  fi

  case "$1" in
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.xz|*.txz) tar xJf "$1" ;;
    *.zip) unzip "$1" ;;
    *.gz) gunzip "$1" ;;
    *) echo "unknown archive: $1"; return 1 ;;
  esac
}

# Use eza if available.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias l='eza'
  alias ll='eza -lh'
  alias la='eza -la'
fi

# Better cd if available.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# Cross-platform clipboard helpers.
if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
  : # macOS already has pbcopy and pbpaste.
elif command -v xclip >/dev/null 2>&1; then
  pbcopy() { xclip -selection clipboard; }
  pbpaste() { xclip -selection clipboard -o; }
elif command -v xsel >/dev/null 2>&1; then
  pbcopy() { xsel --clipboard --input; }
  pbpaste() { xsel --clipboard --output; }
else
  pbcopy() { cat >/dev/null; }
  pbpaste() { return 1; }
fi

# Prompt with time, directory, and last exit code.
__prompt() {
  local ec="$1"
  local c='\[\033[1;36m\]'
  local y='\[\033[1;33m\]'
  local g='\[\033[1;32m\]'
  local r='\[\033[1;31m\]'
  local m='\[\033[1;35m\]'
  local x='\[\033[0m\]'
  local s="${g}${ec}${x}"

  [ "$ec" -ne 0 ] && s="${r}${ec}${x}"

  PS1="${c}\A${x} :: ${y}\w${x} :: ${s}\n${m}#${x} "
}

PROMPT_COMMAND='__ec=$?; history -a; history -n; __prompt "$__ec"'

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

manpath_prepend() {
  case ":${MANPATH:-}:" in
    *":$1:"*) ;;
    *) MANPATH="$1${MANPATH:+:$MANPATH}" ;;
  esac
}

# Homebrew paths.
path_prepend "/opt/homebrew/bin"
path_prepend "$HOME/brew/bin"

for d in /opt/homebrew/opt/*/libexec/gnubin; do
  [ -d "$d" ] && path_prepend "$d"
done

for d in /opt/homebrew/opt/*/libexec/gnuman; do
  [ -d "$d" ] && manpath_prepend "$d"
done

# Conda / Miniforge path.
path_prepend "$HOME/miniforge/bin"

export PATH
export MANPATH
```

Put this in `~/.bash_profile`:

```bash
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
```

For Zsh, keep the same aliases and functions, but put them in `~/.zshrc`. The `bind` commands are Bash-specific and should be rewritten with `bindkey` if needed.

---

## Neovim Setup

Minimal config. No plugin manager. Good enough for remote servers.

Put this in `~/.config/nvim/init.lua`:

```lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.shiftround = true
vim.opt.clipboard = "unnamedplus"
vim.opt.wrap = false
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.signcolumn = "yes"

local map = vim.keymap.set
local opts = { silent = true }

map("n", "<leader>w", "<cmd>w<cr>", opts)
map("n", "<leader>q", "<cmd>q<cr>", opts)
map("n", "<leader>x", "<cmd>wq<cr>", opts)
map("n", "<esc>", "<cmd>nohlsearch<cr>", opts)
map("i", "jk", "<esc>", opts)

local function set_transparent_bg()
  local groups = {
    "Normal",
    "NormalNC",
    "SignColumn",
    "EndOfBuffer",
    "LineNr",
    "CursorLineNr",
    "FoldColumn",
    "StatusLine",
    "StatusLineNC",
    "NormalFloat",
    "FloatBorder",
    "Pmenu",
  }

  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_transparent_bg,
})

set_transparent_bg()
```

Useful keys:

| Key | Action |
|---|---|
| `<leader>w` | save |
| `<leader>q` | quit |
| `<leader>x` | save and quit |
| `jk` in insert mode | escape |
| `<esc>` in normal mode | clear search highlight |

---

## tmux Setup

Put this in `~/.tmux.conf`:

```tmux
unbind C-b
set -g prefix C-a
bind C-a send-prefix

set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm-256color:RGB"
set -g escape-time 0
set -g history-limit 50000
set -g renumber-windows on
set -g base-index 1
setw -g pane-base-index 1

set -g mouse on
setw -g mode-keys vi
set -g set-clipboard on

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

bind z resize-pane -Z
bind r source-file ~/.tmux.conf \; display-message "tmux reloaded"

set -g status-bg black
set -g status-fg white
set -g status-left ' #S '

set -g window-status-format ' [#I:#W] '
set -g window-status-style 'fg=white,bg=black'
set -g window-status-current-format ' #[bold,fg=black,bg=white][#I:#W]#[] '
set -g window-status-current-style 'bold,fg=black,bg=white'
```

Common commands:

```bash
tmux new -s main
tmux attach -t main
tmux ls
tmux kill-session -t main
```

Useful keys:

| Key | Action |
|---|---|
| `C-a c` | new window |
| `C-a h/j/k/l` | move between panes |
| `C-a H/J/K/L` | resize panes |
| `C-a z` | zoom pane |
| `C-a r` | reload config |

---

## WezTerm Setup

Put this in `~/.wezterm.lua`:

```lua
local wezterm = require "wezterm"
local config = wezterm.config_builder()

config.color_scheme = "Sakura"
config.font = wezterm.font_with_fallback({
  { family = "IBM Plex Mono", weight = "Bold" },
  { family = "JetBrains Mono", weight = "Bold" },
})
config.font_size = 16.0
config.window_background_opacity = 0.75
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

return config
```

Do not commit font files into your dotfiles repo. Keep only the config.

---

## Version-Controlled Dotfiles

A bare Git repo is a clean way to version files directly under `$HOME` without symlinks.

### 1. Define variables

Put this in `~/.bashrc` or `~/.zshrc`:

```bash
export DOTFILES_REPO="git@github.com:tiendu/dotfiles.git"
export DOTFILES_DIR="$HOME/.dotfiles"
alias config='/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME'
```

Reload the shell:

```bash
source ~/.bashrc
```

### 2. First-time setup on a new machine

```bash
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
config checkout
config config --local status.showUntrackedFiles no
```

If `config checkout` fails because files already exist, back them up first:

```bash
mkdir -p "$HOME/.dotfiles-backup"

config checkout 2>&1 | awk '/would be overwritten/ {flag=1; next} flag && NF {print $1}' | while read -r file; do
  mkdir -p "$HOME/.dotfiles-backup/$(dirname "$file")"
  mv "$HOME/$file" "$HOME/.dotfiles-backup/$file"
done

config checkout
```

### 3. Daily usage

```bash
config status
config add ~/.bashrc ~/.tmux.conf ~/.config/nvim/init.lua
config commit -m "Update dotfiles"
config push
```

---

## Environment Managers

Use one tool per job.

- SDKMAN for Java
- Miniforge or Pixi for Python / Conda-style environments
- Nix for isolated CLI tools
- Homebrew for macOS CLI tools

Avoid mixing too many environment managers in the same project unless there is a clear reason.

### Java with SDKMAN

Install SDKMAN:

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

List available Java versions:

```bash
sdk list java
```

Install a Java 17 build:

```bash
sdk install java 17-tem
sdk use java 17-tem
java -version
```

For reproducible projects, pin a specific version after checking `sdk list java`.

### Pixi

Pixi is useful for reproducible project environments.

Global sync:

```bash
pixi global sync
```

Create a new environment:

```bash
pixi init dev-env
cd dev-env
pixi add python git curl zip unzip
pixi shell
```

Example `pixi.toml`:

```toml
[project]
name = "dev-env"
version = "0.1.0"
description = "Small reproducible development environment"
channels = ["conda-forge", "bioconda"]
platforms = ["linux-64"]

[tasks]
hello = "python --version"

[dependencies]
python = ">=3.11,<3.13"
git = ">=2.40"
curl = ">=8"
zip = ">=3"
unzip = ">=6"
```

Avoid destructive Pixi tasks like this unless you really mean it:

```bash
rm -rf "$HOME/.config"
```

Safer pattern:

```bash
mv "$HOME/.config" "$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
```

### Miniforge

Auto-detect macOS or Linux and install Miniforge:

```bash
set -euo pipefail

case "$(uname)" in
  Darwin)
    installer="Miniforge3-MacOSX-$(uname -m).sh"
    ;;
  Linux)
    installer="Miniforge3-Linux-$(uname -m).sh"
    ;;
  *)
    echo "Unsupported OS"
    exit 1
    ;;
esac

url="https://github.com/conda-forge/miniforge/releases/latest/download/$installer"
wget "$url"
sh "$installer" -b -u -p "$HOME/miniforge"
rm "$installer"
```

Add to shell config:

```bash
export PATH="$HOME/miniforge/bin:$PATH"
```

### R First-Time Setup

Ubuntu/Debian packages for building common R packages:

```bash
sudo apt update
sudo apt install -y \
  r-base-dev \
  build-essential \
  libnlopt-dev \
  libfontconfig1-dev \
  libxml2-dev \
  libgsl-dev \
  cmake \
  libssl-dev \
  libcurl4-openssl-dev
```

### Nix CLI Package Install Script

```bash
#!/usr/bin/env sh
set -eu

packages="curl aria2 git zip unzip gawk fish openssh tmux nmap jq eza ripgrep bat fzf yazi fd zoxide entr"

for pkg in $packages; do
  echo "Installing $pkg..."
  nix profile install "nixpkgs#$pkg"
done

echo "All packages installed."
```

---

## Containers

### Podman Basics

Install Podman:

```bash
sudo apt update
sudo apt install -y podman uidmap fuse-overlayfs
```

Check setup:

```bash
podman info
podman run --rm docker.io/library/alpine:latest echo hello
```

Build an image:

```bash
podman build -t my-image .
podman run --rm my-image
```

### Podman in GitHub Codespaces

```bash
pixi global install podman
sudo apt-get update
sudo apt-get install -y uidmap fuse-overlayfs
podman info
```

If Podman has registry policy issues in a disposable Codespace, you may use a permissive policy. Do not use this on a real workstation or shared server.

```bash
mkdir -p ~/.config/containers
cat > ~/.config/containers/policy.json <<'JSON'
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ]
}
JSON
chmod 644 ~/.config/containers/policy.json
```

Build with host networking only if needed:

```bash
podman build --network host -t my-image .
```

---

## Linux Laptop and Desktop Fixes

### Battery Optimization with TLP

Install TLP:

```bash
sudo apt update
sudo apt install -y tlp tlp-rdw
sudo systemctl enable tlp
sudo systemctl start tlp
```

Check status:

```bash
tlp-stat -s
```

Optional `/etc/tlp.conf` settings:

```conf
CPU_SCALING_GOVERNOR_ON_BAT=powersave
USB_AUTOSUSPEND=1
```

ThinkPad-only packages may help on older ThinkPads, but do not install them blindly on every machine:

```bash
sudo apt install -y acpi-call-dkms tp-smapi-dkms
```

### Suspend on Lid Close

Edit logind config:

```bash
sudo nvim /etc/systemd/logind.conf
```

Set:

```conf
HandleLidSwitch=suspend
```

Restart:

```bash
sudo systemctl restart systemd-logind.service
```

### GRUB Timeout

Edit:

```bash
sudo nvim /etc/default/grub
```

Set:

```conf
GRUB_TIMEOUT=0
```

Apply:

```bash
sudo update-grub
```

### Disable Wayland for Remote Desktop Compatibility

Some remote desktop tools work better on Xorg than Wayland.

Edit:

```bash
sudo nvim /etc/gdm3/custom.conf
```

Set:

```conf
WaylandEnable=false
```

Restart the display manager or reboot.

### Yakuake Config

Edit:

```bash
nvim ~/.config/yakuakerc
```

Common settings to adjust:

- height
- width
- screen position
- animation speed

### Install Fonts

Download fonts manually, then install them into your user font directory:

```bash
mkdir -p "$HOME/.local/share/fonts"
unzip font.zip -d "$HOME/.local/share/fonts"
fc-cache -fv
```

Do not commit font files into Git unless the license clearly allows it.

### Prevent Sleep

Use this only on machines that should stay awake, such as a workstation running long jobs.

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```

Undo:

```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### Swap Ctrl and Caps Lock

Edit:

```bash
sudo nvim /etc/default/keyboard
```

Set:

```conf
XKBOPTIONS="ctrl:nocaps"
```

Apply after reboot, or run:

```bash
sudo dpkg-reconfigure keyboard-configuration
```

---

## Storage and Filesystem

### Format and Mount a New Drive

Be careful. This destroys data on the target disk.

Check disks first:

```bash
lsblk -f
```

Partition:

```bash
sudo parted /dev/sdX
```

Inside `parted`:

```text
mklabel gpt
mkpart primary ext4 0% 100%
quit
```

Format and mount:

```bash
sudo mkfs.ext4 /dev/sdX1
sudo mkdir -p /mnt/data
sudo mount /dev/sdX1 /mnt/data
```

Find UUID:

```bash
blkid /dev/sdX1
```

Add to `/etc/fstab`:

```fstab
UUID=<uuid> /mnt/data ext4 defaults,nofail 0 2
```

### Increase Swap Space

```bash
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
```

Persist in `/etc/fstab`:

```fstab
/swapfile none swap sw 0 0
```

### Software RAID 5

Warning: RAID is not backup. It only protects against some disk failures.

Install:

```bash
sudo apt update
sudo apt install -y mdadm
```

Create RAID 5:

```bash
sudo mdadm --create --verbose /dev/md0 \
  --level=5 \
  --raid-devices=3 \
  /dev/sda1 /dev/sdb1 /dev/sdc1
```

Format and mount:

```bash
sudo mkfs.ext4 /dev/md0
sudo mkdir -p /mnt/raid
sudo mount /dev/md0 /mnt/raid
```

Check status:

```bash
watch cat /proc/mdstat
sudo mdadm --detail /dev/md0
```

Save array config:

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

Example recovery flow:

```bash
sudo mdadm --stop /dev/md127
sudo mdadm --assemble --force /dev/md127 /dev/sda1 /dev/sdb1
sudo mdadm --add /dev/md127 /dev/sdc1
```

### Shared Filesystem with NFS

On controller/server:

```bash
sudo apt install -y nfs-kernel-server
sudo mkdir -p /shared_directory
sudo chown nobody:nogroup /shared_directory
sudo chmod 775 /shared_directory
```

Add to `/etc/exports`:

```exports
/shared_directory hpc02(rw,sync,no_subtree_check)
```

Apply:

```bash
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

On worker/client:

```bash
sudo apt install -y nfs-common
sudo mkdir -p /shared_directory
sudo mount hpc01:/shared_directory /shared_directory
```

Persist in `/etc/fstab` on the client:

```fstab
hpc01:/shared_directory /shared_directory nfs defaults,_netdev 0 0
```

Avoid `no_root_squash` unless you fully trust the client machines.

### Encrypted Directory with gocryptfs

Install:

```bash
sudo apt install -y gocryptfs
```

Create encrypted and mounted directories:

```bash
mkdir -p "$HOME/encrypted_directory" "$HOME/mounted_directory"
gocryptfs -init "$HOME/encrypted_directory"
```

Mount:

```bash
gocryptfs "$HOME/encrypted_directory" "$HOME/mounted_directory"
```

Unmount:

```bash
fusermount -u "$HOME/mounted_directory"
```

### Create a Fake Large File

Sparse file:

```bash
fallocate -l 5T testfile.txt
```

Alternative:

```bash
truncate -s 5T testfile.txt
dd if=/dev/urandom of=testfile.txt bs=1M count=10 conv=notrunc
```

A sparse file may appear huge but use little real disk space.

---

## User and Permission Management

### Create a User

```bash
sudo useradd -m guest
sudo passwd guest
sudo chage -d 0 guest
```

Add to group:

```bash
sudo usermod -aG guests guest
```

### List Normal Users

```bash
awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
```

### Disk Usage by User

From the target directory:

```bash
sudo find . -type f -printf "%u %s\n" \
  | awk '{user[$1]+=$2} END {for (i in user) print i, int(user[i]/(1024^3)) " GB"}' \
  | sort -k2 -nr
```

### Directory Group Permissions

```bash
sudo chgrp -R group /path/to/dir
sudo chmod -R g+rwX /path/to/dir
sudo find /path/to/dir -type d -exec chmod g+s {} \;
setfacl -R -m g:group:rwx /path/to/dir
setfacl -R -d -m g:group:rwx /path/to/dir
```

The `g+s` bit makes new files inherit the directory group.

### Primary and Secondary Groups

Set primary group:

```bash
sudo usermod -g group user
```

Add secondary group:

```bash
sudo usermod -aG group user
```

Remove from group:

```bash
sudo deluser user group
```

### Resource Limits

Edit:

```bash
sudo nvim /etc/security/limits.conf
```

Example:

```conf
username soft as 8192
username hard as 8192
* soft nproc 100
* hard nproc 200
```

Temporary memory limit for current shell:

```bash
ulimit -S -v 16384
```

### Fix Too Many Open Files

Temporary:

```bash
ulimit -n 4096
```

Permanent:

Edit `/etc/security/limits.conf`:

```conf
* soft nofile 4096
* hard nofile 4096
```

Ensure PAM applies limits:

```bash
sudo nvim /etc/pam.d/common-session
sudo nvim /etc/pam.d/common-session-noninteractive
```

Add:

```conf
session required pam_limits.so
```

---

## SLURM Notes

These notes are for a small local or lab cluster, not a production HPC center.

### Single-Node Setup

Install packages:

```bash
sudo apt update
sudo apt install -y munge slurm-wlm
```

Start Munge:

```bash
sudo systemctl enable munge
sudo systemctl start munge
```

Check node hardware as SLURM sees it:

```bash
slurmd -C
```

Use the output to build the `NodeName` line in `/etc/slurm/slurm.conf`.

Example minimal `/etc/slurm/slurm.conf`:

```conf
ClusterName=localcluster
SlurmctldHost=localhost
MpiDefault=none
ProctrackType=proctrack/linuxproc
ReturnToService=2

SlurmctldPidFile=/run/slurmctld.pid
SlurmctldPort=6817
SlurmdPidFile=/run/slurmd.pid
SlurmdPort=6818
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=slurm
StateSaveLocation=/var/spool/slurmctld

SwitchType=switch/none
TaskPlugin=task/none

InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
Waittime=0

SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core

AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/none
JobAcctGatherType=jobacct_gather/none

SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm/slurmd.log

# Replace this with output from: slurmd -C
NodeName=localhost CPUs=8 RealMemory=32000 State=UNKNOWN
PartitionName=local Nodes=localhost Default=YES MaxTime=INFINITE State=UP
```

Prepare directories:

```bash
sudo install -o slurm -g slurm -m 755 -d /var/spool/slurmctld
sudo install -o slurm -g slurm -m 755 -d /var/spool/slurmd
sudo install -o slurm -g slurm -m 755 -d /var/log/slurm
sudo touch /var/log/slurm/slurmctld.log /var/log/slurm/slurmd.log
sudo chown slurm:slurm /var/log/slurm/*.log
```

Start services:

```bash
sudo systemctl enable slurmctld slurmd
sudo systemctl start slurmctld slurmd
```

Check status:

```bash
sinfo
scontrol show node
srun hostname
```

Do not use this pattern:

```bash
sudo chmod -R 777 /var/log /var/lib
```

It is too broad and unsafe.

### Multi-Node Setup

On all nodes, update `/etc/hosts`:

```hosts
127.0.0.1   localhost
172.16.1.15 hpc01
172.16.1.16 hpc02
```

Set up passwordless SSH from controller to workers:

```bash
ssh-keygen -t ed25519
ssh-copy-id username@hpc02
```

In `/etc/ssh/sshd_config`, ensure:

```conf
PubkeyAuthentication yes
PasswordAuthentication no
```

Copy Munge key from controller to workers:

```bash
sudo scp /etc/munge/munge.key user@hpc02:/tmp/munge.key
ssh user@hpc02 'sudo mv /tmp/munge.key /etc/munge/munge.key && sudo chown munge:munge /etc/munge/munge.key && sudo chmod 400 /etc/munge/munge.key && sudo systemctl restart munge'
```

Ensure the same `/etc/slurm/slurm.conf` exists on all nodes.

Firewall:

```bash
sudo ufw allow ssh
sudo ufw allow 6817:6819/tcp
sudo ufw reload
```

Check connectivity:

```bash
nc -vz hpc01 6817
nc -vz hpc02 6818
```

Check cluster:

```bash
sinfo
scontrol show nodes
```

---

## Nextflow Notes

### System-Wide Installation

Install Java:

```bash
sudo apt update
sudo apt install -y openjdk-17-jre-headless
java -version
```

Install Nextflow:

```bash
curl -fsSL https://get.nextflow.io | bash
sudo install -m 755 nextflow /usr/local/bin/nextflow
nextflow -version
```

Avoid this:

```bash
sudo chmod 777 /usr/local/bin/nextflow
```

Use `install -m 755` instead.

### Local Pipeline Run Checklist

Prepare:

- input files
- reference files
- sample sheet such as `design.csv`
- `nextflow.config`
- container image access
- enough disk space for `work/`

Install AWS ECR helper if the container is stored in AWS ECR:

```bash
sudo apt install -y amazon-ecr-credential-helper
mkdir -p ~/.docker
printf '{"credsStore":"ecr-login"}\n' > ~/.docker/config.json
```

Configure AWS credentials without committing them:

```bash
aws configure
```

Or use environment variables for a temporary shell:

```bash
export AWS_ACCESS_KEY_ID="<access-key-id>"
export AWS_SECRET_ACCESS_KEY="<secret-access-key>"
export AWS_DEFAULT_REGION="us-east-1"
```

Never store real AWS keys in dotfiles or public notes.

Pull image:

```bash
docker pull <account>.dkr.ecr.us-east-1.amazonaws.com/<image>:<tag>
```

Run:

```bash
nextflow run main.nf \
  -profile docker \
  -work-dir workdir \
  --awsregion us-west-2 \
  --genome <genome_name> \
  --design design.csv \
  --outdir results \
  --protocol <protocol_name> \
  --name <run_name> \
  --maxMemory 120.GB
```

Useful resume command:

```bash
nextflow run main.nf -resume -profile docker
```

Common checks:

```bash
nextflow log
nextflow log <run-name-or-id>
du -sh work results
```

---

## Termux Setup

Install packages:

```bash
pkg update -y && pkg upgrade -y && pkg autoclean && pkg clean

pkg install -y \
  neovim \
  ripgrep \
  fd \
  fzf \
  bat \
  tmux \
  zsh \
  coreutils \
  git \
  jq \
  eza \
  zoxide \
  podman \
  wget \
  curl \
  tldr \
  nodejs \
  zip \
  unzip
```

Enable storage access:

```bash
termux-setup-storage
```

Customize extra keys:

```bash
mkdir -p "$HOME/.termux"
cat >> "$HOME/.termux/termux.properties" <<'CONF'
extra-keys = [['ESC', 'TAB', 'CTRL', 'ALT', 'SHIFT', 'DEL', 'BACKSLASH', 'KEYBOARD'], ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'HOME', 'PGUP'], ['F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'END', 'PGDN'], ['LEFT', 'UP', 'DOWN', 'RIGHT', '/', '|', 'QUOTE', 'APOSTROPHE']]
CONF
termux-reload-settings
```

Restart Termux after reloading settings.

---

## Useful CLI Tricks

### Fast Download with aria2

```bash
aria2c "https://ftp.ensembl.org/pub/release-110/variation/indexed_vep_cache/homo_sapiens_merged_vep_110_GRCh38.tar.gz" \
  -x 8 \
  -s 16 \
  -j 3
```

### Find Binary Location

```bash
whereis <binary>
command -v <binary>
```

### Hard Links

Create hard link:

```bash
ln <src> <dest>
```

Check link count:

```bash
stat -c %h <file>
```

### Wait for a Process Before Running Another Command

```bash
while kill -0 <pid> 2>/dev/null; do
  sleep 1
done

<next_command>
```

Find process:

```bash
pgrep -af <command>
```

### Git: Reset to First Commit and Squash History

Warning: this rewrites Git history.

```bash
git reset "$(git rev-list --max-parents=0 HEAD)"
git add -A
git commit -m "Initial squashed commit"
git push origin <branch-name> --force-with-lease
```

Prefer `--force-with-lease` over `--force`.

### Clone All Repos from a GitHub Organization

```bash
gh repo list <your_org> --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner' \
  | while read -r repo; do
      gh repo clone "$repo" "$repo" -- -q 2>/dev/null || (
        cd "$repo"
        git checkout -q main 2>/dev/null || true
        git checkout -q master 2>/dev/null || true
        git pull -q
      )
    done
```

Faster version:

```bash
gh repo list <your_org> --limit <limit> --json nameWithOwner --jq '.[].nameWithOwner' \
  | xargs -I {} -P <threads> gh repo clone {}
```

### Start a Script at Boot with systemd

Create service:

```bash
sudo nvim /etc/systemd/system/my-script.service
```

Example:

```ini
[Unit]
Description=My Script Service
After=network.target

[Service]
ExecStart=/path/to/your/script.sh
Restart=always
User=your_username
WorkingDirectory=/home/your_username

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable my-script.service
sudo systemctl start my-script.service
sudo systemctl status my-script.service
```

### CLI Email Sending with msmtp

Install:

```bash
sudo apt install -y mailutils msmtp
```

Create `~/.msmtprc`:

```conf
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account gmail
host smtp.gmail.com
port 587
auth on
user your@gmail.com
password <app-password>
from your@gmail.com
```

Lock down permissions:

```bash
chmod 600 ~/.msmtprc
```

Send test:

```bash
echo "This is a test email" | msmtp -a gmail your@gmail.com
```

Do not commit `.msmtprc` if it contains a password.

### GitHub Private Repo Access Across Organizations

Simple model:

1. The same owner must control both organizations.
2. Private repo forking must be allowed in the source organization.
3. Fork private repos from Org A to Org B.
4. Add users to Org B only.
5. Users can access the forked repos but not the original Org A repos.

This is useful when you need to share code with a smaller group without exposing the original organization.

---

## Security Notes

Keep these rules boring and strict.

### Do Not Commit Secrets

Never commit:

- AWS access keys
- API tokens
- SSH private keys
- app passwords
- `.env` files with real credentials
- private certificates
- customer data

Use placeholders in notes:

```bash
export AWS_ACCESS_KEY_ID="<access-key-id>"
export AWS_SECRET_ACCESS_KEY="<secret-access-key>"
```

### Avoid `chmod 777`

Usually, `chmod 777` means the permission model was not designed.

Prefer:

```bash
sudo chown -R user:group /path/to/dir
sudo chmod -R u+rwX,g+rwX,o-rwx /path/to/dir
```

For shared directories:

```bash
sudo chmod -R g+rwX /path/to/dir
sudo find /path/to/dir -type d -exec chmod g+s {} \;
```

### Be Careful with Insecure Container Policies

This is unsafe on real machines:

```json
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ]
}
```

Only use it inside disposable environments when you understand the trade-off.

### Keep Dotfiles Public-Safe

Before pushing:

```bash
git status
git diff --cached
```

Search for secrets:

```bash
rg -i "aws_secret|secret_access|password|token|private key|BEGIN OPENSSH" .
```

---

## Recovery Checklist

When setting up a fresh machine:

```bash
# 1. Install base packages.
sudo apt update && sudo apt install -y git curl neovim tmux ripgrep fd-find fzf jq

# 2. Clone dotfiles.
export DOTFILES_REPO="git@github.com:tiendu/dotfiles.git"
export DOTFILES_DIR="$HOME/.dotfiles"
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

# 3. Define alias.
alias config='/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME'

# 4. Checkout.
config checkout
config config --local status.showUntrackedFiles no

# 5. Reload shell.
source ~/.bashrc

# 6. Start tmux.
tmux new -s main
```

If checkout conflicts with existing files:

```bash
mkdir -p ~/.dotfiles-backup
mv ~/.bashrc ~/.dotfiles-backup/ 2>/dev/null || true
mv ~/.tmux.conf ~/.dotfiles-backup/ 2>/dev/null || true
mv ~/.config/nvim ~/.dotfiles-backup/nvim 2>/dev/null || true
config checkout
```

Final sanity checks:

```bash
nvim --version
tmux -V
git --version
rg --version
fd --version 2>/dev/null || fdfind --version
```
