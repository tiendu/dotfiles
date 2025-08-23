## Minimalist Development Tools

```bash
sudo apt update && sudo apt upgrade -y && \
sudo apt install neovim tmux coreutils git podman wget curl unzip zip htop
```

Minimal footprint configs:

```
# ~/.zshrc
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
alias e='nvim'
alias l='ls'
alias z='cd'
alias g='git'
export EDITOR='nvim'
autoload -Uz compinit; compinit
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt extended_history
PROMPT='%F{magenta}>>>%f %F{cyan}%D{%H:%M:%S}%f :: %F{yellow}%~%f $ '
```

```
-- ~/.config/nvim/init.lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = "unnamedplus"
local transparent_groups = {
  "Normal",
  "NormalFloat",
  "FloatBorder",
  "Pmenu",
  "PmenuSel",
}
for _, group in ipairs(transparent_groups) do
  vim.api.nvim_set_hl(0, group, { bg = "none" })
end
```

```
# ~/.tmux.conf
unbind C-b
set -g prefix C-a
bind C-a send-prefix
set -g mouse on
setw -g mode-keys vi
set-option -g set-clipboard on
```

```
-- ~/.wezterm.lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.color_scheme = 'Homebrew'

config.font = wezterm.font_with_fallback {
  weight = 'Bold',
}
config.font_size = 16.0
config.window_background_opacity = 0.75

return config
```

## Linux Battery Optimization

```bash
sudo apt update && sudo apt install tlp tlp-rdw acpi-call-dkms tp-smapi-dkms && sudo tlp start
```

Check status:

```bash
tlp-stat -s
```

Add these to `/etc/tlp.conf`:

```
CPU_SCALING_GOVERNOR_ON_BAT=powersave
USB_AUTOSUSPEND=1
```

## Java Installation with SDKMAN

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

sdk install java 17.0.9-tem
sdk use java 17.0.9-tem
```

## Version-Controlled Dotfiles

### Step 1: Define the environment variable (e.g. in `.zshrc` or `.bashrc`)

```bash
export DOTFILES_REPO="git@github.com:tiendu/dotfiles.git"
export DOTFILES_DIR="$HOME/.dotfiles"
```

### Step 2: Use it in your setup

```bash
# Clone the dotfiles repo as a bare repo
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

# Define the `config` alias
alias config='/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME'

# Checkout your dotfiles into $HOME
config checkout
config config --local status.showUntrackedFiles no
```

### Bonus: Add the alias permanently

```bash
echo 'alias config="/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME"' >> ~/.zshrc
```

You can also export the variables there if you want them available every time:

```bash
echo 'export DOTFILES_REPO="git@github.com:tiendu/dotfiles.git"' >> ~/.zshrc
echo 'export DOTFILES_DIR="$HOME/.dotfiles"' >> ~/.zshrc
```

## `pixi.sh` Environment Setup

Use pixi to manage reproducible environments:

```bash
pixi global sync  # for global
```

For custom env:

```bash
pixi init <env>
```

Edit `pixi.toml`:

```toml
[project]
channels = ["conda-forge", "bioconda"]
description = "dev env"
name = "ubuntu"
platforms = ["linux-64"]
version = "0.1.0"

[tasks]
start = { cmd="rm -rf dotfiles && git clone https://github.com/tiendu/dotfiles && rm -rf $HOME/.config && mv dotfiles/.config $HOME/ && fish"}

[dependencies]
python = ">=3.7.0,<3.8"
git = ">=2.47.1,<3"
curl = ">=8.11.1,<9"
zip = ">=3.0,<4"
unzip = ">=6.0,<7"
```

Then `pixi install && pixi shell`.

## `podman` in GitHub Codespaces

```bash
# Install podman globally using Pixi (if not already installed)
pixi global install podman

# Install necessary dependencies to support podman
sudo apt-get update && sudo apt-get install uidmap fuse-overlayfs

# Create a configuration directory for Podman
mkdir -p ~/.config/containers

# Create the policy.json file to configure insecure registries
echo '{
  "default": [
      {
          "type": "insecureAcceptAnything"
      }
  ]
}' > ~/.config/containers/policy.json

# Adjust permissions for the policy file
chmod 644 ~/.config/containers/policy.json

# Build your container image using Podman
podman build --network host -t <image_name> .
```

## Miscellaneous Fixes

### Suspend on Lid Close

```bash
# Edit systemd logind configuration to suspend on lid close
sudo vi /etc/systemd/logind.conf
# Uncomment: HandleLidSwitch=suspend
sudo systemctl restart systemd-logind.service
```

### Grub Timeout

```bash
# Edit GRUB configuration to disable timeout during boot
sudo vi /etc/default/grub
# Set GRUB_TIMEOUT=0 to skip boot menu
sudo update-grub
```

### Yakuake Config

Edit `~/.config/yakuakerc` and adjust height/position.

### Install Font

Download [Intel One Mono](https://github.com/intel/intel-one-mono) then `unzip font.zip -d .fonts && fc-cache -fv`.

### Turn Off Wayland (for `anydesk`, `vnc`)

```bash
# Edit the GDM configuration to disable Wayland for better compatibility with applications like AnyDesk and VNC
sudo vi /etc/gdm3/custom.conf
# Uncomment: WaylandEnable=false
```

Some remote desktop applications (like `anydesk` or `vnc`) are not fully compatible with Wayland. Disabling Wayland allows these tools to work better.

## SLURM Configuration

### Single-node Setup

1. Install SLURM and dependencies: `sudo apt install slurm slurmd slurmctld`

2. Create `/lib/systemd/system/slurmctld.service`:

```
[Unit]
Description=Slurm controller daemon
After=network.target munge.service
ConditionPathExists=/etc/slurm/slurm.conf
Documentation=man:slurmctld(8)

[Service]
Type=forking
EnvironmentFile=-/etc/default/slurmctld
ExecStart=/usr/sbin/slurmctld $SLURMCTLD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/run/slurmctld.pid
LimitNOFILE=65536
TasksMax=infinity

[Install]
WantedBy=multi-user.target
```

3. Create `/lib/systemd/system/slurmd.service`:

```
[Unit]
Description=Slurm node daemon
After=munge.service network.target remote-fs.target
ConditionPathExists=/etc/slurm/slurm.conf
Documentation=man:slurmd(8)

[Service]
Type=forking
EnvironmentFile=-/etc/default/slurmd
ExecStart=/usr/sbin/slurmd $SLURMD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/run/slurmd.pid
KillMode=process
LimitNOFILE=131072
LimitMEMLOCK=infinity
LimitSTACK=infinity
Delegate=yes
TasksMax=infinity

[Install]
WantedBy=multi-user.target
```

4. Configure `/etc/slurm/slurm.conf`:

```
ClusterName=localcluster
SlurmctldHost=localhost
MpiDefault=none
ProctrackType=proctrack/linuxproc
ReturnToService=2
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmctldPort=6817
SlurmdPidFile=/var/run/slurmd.pid
SlurmdPort=6818
SlurmdSpoolDir=/var/lib/slurm-llnl/slurmd
SlurmUser=slurm
StateSaveLocation=/var/lib/slurm-llnl/slurmctld
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
SrunProlog=/usr/bin/podman

AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/none
JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/none
SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurm-llnl/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm-llnl/slurmd.log

NodeName=localhost CPUs=88 Boards=1 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=2 RealMemory=515860 State=UNKNOWN
PartitionName=LocalQ Nodes=ALL Default=YES MaxTime=INFINITE State=UP
```

5. Prepare directories and permissions:

```bash
sudo mkdir -p /var/log/slurm-llnl /var/lib/slurm-llnl
sudo chmod -R 777 /var/log/ /var/lib/
```

6. Reload and start services:

```bash
sudo systemctl daemon-reload
sudo systemctl start slurmd
sudo systemctl start slurmctld
```

### Multi-node Setup

1. Update `/etc/hosts` on all nodes:

```
127.0.0.1   localhost
127.0.1.1   hpc02
172.16.1.15 hpc01
```

2. Set up passwordless SSH:

```bash
ssh-keygen -t rsa
ssh-copy-id username@hostname
```

Ensure `/etc/ssh/sshd_config` has:

```
PubkeyAuthentication yes
PasswordAuthentication no
```

3. Copy Munge key from controller to workers:

```bash
sudo scp /etc/munge/munge.key user@worker:/etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
```

4. Ensure identical `slurm.conf` across all nodes.

5. Firewall setup:

```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 6817:6819/tcp
sudo ufw reload
```

6. Check connectivity:

```
telnet hpc01 6817
```

## Shared Filesystem with NFS

1. On controller:

```bash
sudo mkdir /shared_directory
echo "/shared_directory hpc02(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
sudo service nfs-kernel-server restart
```

2. On worker:

```bash
sudo mkdir /shared_directory
sudo mount hpc01:/shared_directory /shared_directory
```

3. Mount on boot (on worker):

Add to `/etc/fstab`:

```
hpc01:/shared_directory /shared_directory nfs defaults 0 0
```

## User Management

### Create and manage users

```bash
sudo useradd guest
sudo usermod -aG guests guest
sudo passwd guest
sudo chage -d 0 guest
```

### Check disk usage by user (GB)

```bash
sudo find . -type f -printf "%u  %s\n" | awk '{user[$1]+=$2} END {for (i in user) print i, int(user[i]/(1024^3))}'
```

### List all users

```bash
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
```

### Directory group permissions

```bash
sudo chgrp -R group /path/to/dir
sudo chmod -R g+s /path/to/dir
setfacl -d -m g::rwx /path/to/dir
setfacl -d -m o::rx /path/to/dir
```

### Set primary/secondary group

```bash
sudo usermod -g group user
sudo usermod -aG group user
sudo adduser user group
sudo deluser user group
```

### Set system-wide resource limits

Edit `/etc/security/limits.conf`:

```
username soft as 8192
username hard as 8192
* soft nproc 100
* hard nproc 200
```

Apply with:

```bash
ulimit -S -v 16384
```

## Software RAID Setup (RAID 5)

1. Install and create RAID:

```bash
sudo apt install mdadm
sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sda1 /dev/sdb1 /dev/sdc1
```

2. Format and mount RAID volume:

```bash
sudo mkfs.ext4 /dev/md0
sudo mkdir /mnt/rdisk
sudo mount /dev/md0 /mnt/rdisk
```

3. Recovery from disk failure:

```bash
sudo mdadm --stop /dev/md127
sudo mdadm --assemble --force /dev/md127 /dev/sda1 /dev/sdb1
sudo mdadm --add /dev/md127 /dev/sdc1
```

4. Check status:

```bash
watch cat /proc/mdstat
```

## Installing R (First-Time Setup)

To prepare your system for R development, install the following essential packages:

```bash
sudo apt install r-base-dev build-essential libnlopt-dev libfontconfig1 \
libxml2-dev libgsl-dev cmake libssl-dev libcurl4-openssl-dev
```

## Miniforge Installation

```bash
# Auto-detect the system platform
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS detected
    echo "Installing Miniforge for macOS..."
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
    sh Miniforge3-MacOSX-x86_64.sh -b -u -p $HOME/miniforge
elif [[ "$(uname)" == "Linux" ]]; then
    # Linux detected
    echo "Installing Miniforge for Linux..."
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    sh Miniforge3-Linux-x86_64.sh -b -u -p $HOME/miniforge
else
    echo "Unsupported OS. Only macOS and Linux are supported."
    exit 1
fi

# Add Miniforge to your PATH in the shell config file (for Zsh or Bash)
echo 'export PATH="$HOME/miniforge/bin:$PATH"' >> ~/."$(basename $SHELL)"rc

# Reload the shell configuration to apply changes
source ~/."$(basename $SHELL)"rc

# Clean up the installer script
rm Miniforge3-*.sh*
```

## Nextflow Setup

### System-wide Installation for Multi-user Access

1. Install Java:

```bash
sudo apt install openjdk-17-source
```

2. Install Nextflow:

```bash
curl -fsSL get.nextflow.io | bash
sudo mv nextflow /usr/local/bin
sudo chown admin:users /usr/local/bin/nextflow
sudo chmod 777 /usr/local/bin/nextflow
```

3. Ensure `/usr/local/bin` is in the global path:

Add this line to `/etc/bash.bashrc`:

```
export PATH="/usr/local/bin/:$PATH"
```

### Running a Nextflow Pipeline Locally

#### Step 1: Prepare Required Files

Download datasets, reference genomes, and the private AWS key (formatted as `_accessKeys.csv`):


| Access key ID       | Secret access key                |
|---------------------|----------------------------------|
| AKIARXXXXXXXXXXXXX  | SVF+XXXXXXXXXXXXXXXXXXXXXXXXXXXX |

#### Step 2: Configuration Adjustments

Edit `design.csv` and `conf/igenomes.config` as needed.

Tweak `conf/base.config` to match system resources (cores, memory).

#### Step 3: Install Required Tools

```bash
sudo apt install amazon-ecr-credential-helper
aws configure  # Enter AWS keys from _accessKeys.csv
```

#### Step 4: Docker ECR Setup

```bash
mkdir -p ~/.docker
echo '{"credsStore": "ecr-login"}' > ~/.docker/config.json
```

#### Step 5: Handle Docker Image

Pull from AWS ECR:

```bash
docker pull <account>.dkr.ecr.us-east-1.amazonaws.com/<image>:2.2.1
```

Or build your own:

```bash
docker build .
```

Verify:

```bash
docker images
```

#### Step 6: Configure Nextflow to Use Docker Image

Set the `process.container` in `nextflow.config` to the pulled image ID.

Run Nextflow with the `-with-docker` flag.

#### Step 7: Run the Workflow

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

## Termux Setup

### Install Essential Packages

```bash
pkg update -y && pkg upgrade -y && pkg autoclean && pkg clean && \
pkg install neovim ripgrep fd fzf bat tmux zsh coreutils git jq eza zoxide podman wget curl tldr nodejs zip unzip
```

### Customize Extra Keys

```bash
mkdir -p $HOME/.termux
echo "extra-keys = [['ESC', 'TAB', 'CTRL', 'ALT', 'SHIFT', 'DEL', 'BACKSLASH', 'KEYBOARD'], ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'HOME', 'PGUP'], ['F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'END', 'PGDN'], ['LEFT', 'UP', 'DOWN', 'RIGHT', '/', '|', 'QUOTE', 'APOSTROPHE']]" >> $HOME/.termux/termux.properties
termux-reload-settings
sleep 1 && logout
```

### Enable Storage Access

```
termux-setup-storage
```

## Miscellaneous Tips and Utilities

### Homebrew Without `sudo`

```bash
mkdir brew
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C ~/brew
eval "$(~/brew/bin/brew shellenv)"
brew update --force --quiet
```

### Create a Fake 5TB File

```bash
fallocate -l 5T testfile.txt
```

### Git: Reset to First Commit and Squash History

1. Clone your repository
2. Reset to the first commit:

```bash
git reset $(git rev-list --max-parents=0 HEAD)
```

3. Add and commit all changes:

```bash
git add -A
git commit -m "Initial squashed commit"
```

4. Force push:

```bash
git push origin <branch-name> --force
```

### Fast Download with aria2

```bash
aria2c https://ftp.ensembl.org/pub/release-110/variation/indexed_vep_cache/homo_sapiens_merged_vep_110_GRCh38.tar.gz -x 8 -s 16 -j 3 &
```

### System & File Utilities

- Find binary location: `whereis <binary>`
- Create hard link: `link <src> <dest>`
- Check if file is hard-linked: `stat -c %h <file>`

### Format and Mount a New Drive

```bash
sudo parted /dev/sda
# (inside parted)
mklabel gpt
mkpart primary ext4 0% 100%
quit

sudo mkfs.ext4 /dev/sda1
sudo mkdir /mnt/d4t
sudo mount /dev/sda1 /mnt/d4t
```

### Essential CLI Tools via Homebrew

```bash
brew install neovim ripgrep fd fzf bat tmux zsh coreutils git jq eza zoxide podman wget curl tldr node zip unzip
```

### Fix Python3 Install via Homebrew

```bash
brew install util-linux
ln -s "$(brew --prefix util-linux)/include/uuid/uuid.h" "$(brew --prefix)/include/uuid.h"
```

### Enable zoxide in `.bashrc`

```bash
eval "$(zoxide init bash)"
```

### Install Packages with Nix

```bash
#!/bin/sh
packages="curl aria2 git zip unzip gawk fish openssh tmux nmap jq eza ripgrep bat fzf yazi fd zoxide entr"
for pkg in $packages; do
  echo "Installing $pkg..."
  nix profile install nixpkgs#$pkg
done
echo "All packages installed!"
```

### Increase Swap Space

```bash
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
```

### Clone All Repos from a GitHub Organization

```bash
gh repo list <your_org> --limit 1000 | while read -r repo _; do
  gh repo clone $repo $repo -- -q 2>/dev/null || (
    cd $repo
    git checkout -q main 2>/dev/null || true
    git checkout -q master 2>/dev/null || true
    git pull -q
  )
done
```

Faster Alternative Using `xargs`

```bash
gh repo list <your_org> --limit <limit> --json nameWithOwner --jq '.[].nameWithOwner' | \
xargs -I {} -P <threads> bash -c 'gh repo {}'
```

### Wait for a Process to Finish Before Running a Command

```bash
ps aux | grep <command>
while ps -p <pid> > /dev/null; do sleep 1; done && <next_command>
```

### Remap Keys: Swap Ctrl and Caps Lock (Linux)

```bash
sudo nano /etc/default/keyboard
# Add or edit this line:
XKBOPTIONS="ctrl:nocaps"
```

### Fix "Too Many Open Files" Error

#### Temporarily

```bash
ulimit -n 4096
```

#### Permanently

1. Edit `/etc/security/limits.conf`:

```
* soft nofile 4096
* hard nofile 4096
```

2. Edit PAM session configs:

```
sudo nano /etc/pam.d/common-session
sudo nano /etc/pam.d/common-session-noninteractive
```

Add:

```
session required pam_limits.so
```

### Start a Script at System Boot

1. Create a systemd service unit file:

```
sudo nano /etc/systemd/system/my-script.service
```

2. Add the following content:

```
[Unit]
Description=My Script Service
After=network.target

[Service]
ExecStart=/path/to/your/script.sh
Restart=always
User=your_username

[Install]
WantedBy=multi-user.target
```

3. Reload systemd and enable/start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable my-script.service
sudo systemctl start my-script.service
```

### Create an Encrypted Directory with `gocryptfs`

1. Install gocryptfs:

```bash
sudo apt install gocryptfs
```

2. Create and initialize the encrypted directory:

```bash
mkdir ~/encrypted_directory
gocryptfs -init ~/encrypted_directory
```

3. Mount it:

```bash
gocryptfs ~/encrypted_directory ~/mounted_directory
```

4. When done, unmount:

```bash
fusermount -u ~/mounted_directory
```

### Prevent the Computer from Sleeping (Linux)

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```

### CLI Email Sending with `msmtp`

1. Install dependencies:

```bash
sudo apt install mailutils msmtp
```

2. Create an app-specific password in your [Google Account](https://myaccount.google.com/) (enable 2FA first).

3. Edit your `.msmtprc` file:

```bash
nano ~/.msmtprc
```

Example config:

```
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account gmail
host smtp.gmail.com
port 587
auth on
user your@gmail.com
password <your-app-password>
from your@gmail.com
```

4. Send a test email:

```bash
echo "This is a test email" | msmtp -a gmail your@gmail.com
```

### GitHub: Managing Private Repo Access Across Organizations

1. Ownership Requirement: The owner of Org A must also be the owner of Org B.
2. Enable Forking: In Org A, allow forking of private repositories.
3. Forking Private Repositories: The owner forks the private repositories from Org A to Org B.
4. User Access Management: Add users only to Org B. They’ll have access to the forked repos but not to Org A.
