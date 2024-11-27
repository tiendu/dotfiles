# Fix lid not suspend

Edit `logind.conf` with `sudo nano /etc/systemd/logind.conf`.

Uncomment `HandleLidSwitch=suspend`.

Then restart the service with `systemctl restart systemd-logind.service`.

# Fix grub not boot instantly

Either `sudo nano /etc/default/grub` or find the `grub.conf` and adjust the timeout.

# Yakuake settings

Edit `~/.config/yakuakerc` and add the below:

```
[Animation]
Frames=0

[Desktop Entry]
DefaultProfile=

[Dialogs]
FirstRun=false

[Window]
Height=78
KeepAbove=false
Position=46
ShowSystrayIcon=false
ToggleToFocus=true
Width=72
```

# Install font

Good font for programmers: [Intel One Mono](https://github.com/intel/intel-one-mono).

`unzip font.zip -d .fonts` then `cd .fonts/; fc-cache -fv`

# Turn off Wayland (for anydesk, vnc)

Edit `custom.conf` with `sudo nano /etc/gdm3/custom.conf`.

Uncomment `WaylandEnable=false`.

# Slurm configs

## Single node configs

Install packages with `sudo apt install slurm slurmd slurmctld`.

Edit `/lib/systemd/system/slurmctld.service` with below.

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

Then edit `/lib/systemd/system/slurmd.service` with below.

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

Now edit `/etc/slurm/slurm.conf` (very important) with below.

```
# slurm.conf file generated by configurator.html.
# Put this file on all nodes of your cluster.
# See the slurm.conf man page for more information.
#
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
#
# TIMERS
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
Waittime=0
# SCHEDULING
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core
SrunProlog=/usr/bin/podman
#
#AccountingStoragePort=
AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/none
JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/none
SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurm-llnl/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm-llnl/slurmd.log
#
# COMPUTE NODES -- Get computer information from `slurmd -C`
NodeName=localhost CPUs=88 Boards=1 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=2 RealMemory=515860 State=UNKNOWN
PartitionName=LocalQ Nodes=ALL Default=YES MaxTime=INFINITE State=UP
```

Change permission of these directories.

```
sudo mkdir -p /var/log/slurm-llnl && sudo chmod -R 777 /var/log/; sudo mkdir -p /var/lib/slurm-llnl && sudo chmod -R 777 /var/lib/
```

Reload with `sudo systemctl daemon-reload` and start the services `sudo systemctl start slurmd.service` and `sudo systemctl start slurmctld.service`.

## Multi nodes configs

1) Edit the `/etc/hosts` on the controller node to include the IP and the hostname of the worker nodes and on the worker nodes, the `hosts` must contain the IP and hostname of the controlller node.

```
...
127.0.0.1   localhost                                                           
127.0.1.1   hpc02                                                               
172.16.1.15 hpc01
...
```

2) Get passwordless ssh ready for worker nodes.
    * Generate rsa key by `ssh-keygen -t rsa`.
    * Use `ssh-copy-id username@hostname` to copy the key from controller node to worker nodes.
    * Edit `/etc/ssh/sshd_config` on worker nodes and ensure these are correct: `PubkeyAuthentication yes` and `PasswordAuthentication no`.
3) Copy Munge key from `/etc/munge/munge.key` from controller node to the exact path on worker nodes.
    * Change ownership on worker nodes with `sudo chown munge:munge /etc/munge/munge.key`.
    * Set permission on worker nodes `sudo chmod 400 /etc/munge/munge.key`.
4) Ensure the `slurm.conf` is identical for the controller node and all its worker nodes.

```
# slurm.conf file
ClusterName=localcluster
SlurmctldHost=hpc01
MpiDefault=none
ProctrackType=proctrack/linuxproc
ReturnToService=2
SlurmctldPidFile=/run/slurmctld.pid
SlurmctldPort=6817
SlurmdPidFile=/run/slurmd.pid
SlurmdPort=6818
SlurmdSpoolDir=/var/lib/slurm-llnl/slurmd
SlurmUser=slurm
StateSaveLocation=/var/lib/slurm-llnl/slurmctld
SwitchType=switch/none
TaskPlugin=task/none
#
# TIMERS
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
Waittime=0
# SCHEDULING
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core
SrunProlog=/usr/bin/podman
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm-llnl/slurmd.log

#
#AccountingStoragePort=
AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/none
JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/none
SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurm-llnl/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm-llnl/slurmd.log
#
# COMPUTE NODES
NodeName=hpc01 CPUs=88 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=2 RealMemory=50000 State=UNKNOWN
NodeName=hpc02 CPUs=88 SocketsPerBoard=2 CoresPerSocket=22 ThreadsPerCore=2 RealMemory=50000 State=UNKNOWN
PartitionName=localcluster Nodes=ALL Default=YES MaxTime=INFINITE State=UP
```

_Should there be any errors for multi-node configuration, please ensure..._
* Firewall is working correctly using the following.
    * Enable ufw first with `sudo ufw enable`.
    * `sudo ufw allow ssh`.
    * `sudo ufw allow 6817:6819/tcp`.
    * `sudo ufw reload`.
* Use telnet to check the communication between nodes with `telnet hpc01 6817`.

# Shared filesystem with `nfs-kernel` and `nfs-common`

1) Create shared directory with `sudo mkdir /shared_directory`.
2) Add `/shared_directory hpc02(rw,sync,no_root_squash)` to `/etc/exports`.
3) Restart NFS on the controller node with `sudo service nfs-kernel-server restart`.
4) On the worker nodes, create a mount point for the shared directory with `sudo mkdir /shared_directory`.
5) Then mount it with `sudo mount hpc01:/shared_directory /shared_directory`.
6) Add this line to `/etc/fstab` to ensure the NFS share is mounted at boot `hpc01:/shared_directory /shared_directory nfs defaults 0 0`.

# User management

  1. New user
     
      * Add new user and add that user to a group.

      ```
      sudo useradd guest
      sudo usermod -aG guests guest
      ```

      * Change the password of that user with `sudo passwd user`.
      
      * Prompt password change on first login with `sudo chage -d 0 user`.

  2. Check how each user occupies the disk space (in Gb) with `sudo find . -type f -printf "%u  %s\n" | awk '{user[$1]+=$2} END {for (i in user) print i, int(user[i]/(1024^3))}'`.

  3. List all users with `awk -F: '$3 >= 1000 {print $1}' /etc/passwd`.

  4. Change group access permission of a directory.

  ```
  sudo chgrp -R group /<directory>
  sudo chmod -R g+s /<directory>
  ```

  5. Set default permission for the group and others.

  ```
  setfacl -d -m g::rwx /<directory>
  setfacl -d -m o::rx /<directory>
  ```

  6. Set primary group for user `sudo usermod -g group user` and add user to other group(s) `sudo usermod -aG group user`.

  7. Add user to group `sudo adduser user group` and remove from group `sudo deluser user group`.

  8. System-wide resource limit.

     * Edit limit config `sudo nano /etc/security/limits.conf`.

     * Add limit config:

       ```
       username soft as 8192 # Set RAM soft limit for a user
       username hard as 8192 # Set RAM hard limit for a user
       * soft nproc 100
       * hard nproc 200
       ```
       
       **Use soft for limits that can be increased by the user and hard for limits that cannot be increased.**

     * User can adjust the soft limit with `ulimit -S -v 16384`. This will set the virtual memory soft limit to 16GB.

# Software RAID

Install package `sudo apt install mdadm`.

Create RAID. In this example, I created a RAID 5 with three disks.

`mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sda1 /dev/sdb1 /dev/sdc1`

Format and mount new RAID partition.

```
sudo mkfs -t ext4 /dev/md0
sudo mkdir /mnt/rdisk
```

Check whether RAID partition is correctly formatted with `lsblk -o NAME,UUID,FSTYPE`.

**Recover when disk(s) fails. Remember to do in correct sequence of order!**

Stop the RAID partition.

`sudo mdadm --stop /dev/md127`

Then check by using `lsblk` for any active disks then run below.

`sudo mdadm --verbose --assemble --force /dev/md127 /dev/sda1 dev/sdb1` if two disks (`sda1` and `sdb1`) are active.

When one replaces a new disk or wants to add a new disk to the RAID partition.

`sudo mdadm -add /dev/md127 /dev/sdc1` add `sdc1` to RAID partition.

All the above must be done before mounting, if not data would be lost!

`sudo mount /dev/md127 /mnt/raid_partition`

Now check the recovery rates with `watch cat /proc/mdstat`.

# How to use `podman`

Install with `sudo apt install podman`.

Let's say we want to use `fastqc` then `podman pull quay.io/biocontainers/fastqc:0.12.1`.

Run the container fastqc with `podman run -v /home/user:/home/user --rm quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0 fastqc /home/user/SRR24796243.fastq.gz`.

# First time installing R

These are important packages for R, install with `sudo apt install r-base-dev build-essential libnlopt-dev libfontconfig1 libxml2-dev libgsl-dev cmake libssl-dev libcurl4-openssl-dev`.

# `mamba`

## Single user

`wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && sh Miniforge3-Linux-x86_64.sh -b -u -p $HOME/miniforge && echo 'export PATH="$HOME/miniforge/bin:$PATH"' >> ~/."$(basename $SHELL)"rc && source ~/."$(basename $SHELL)"rc && rm Miniforge3-Linux-x86_64.sh*`

## Multi users

1. Download Mambaforge:

`wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh`

2. Install Mambaforge: Install it in `/opt/mambaforge` to provide system-wide access.

`sudo bash Mambaforge-Linux-x86_64.sh -b -p /opt/mambaforge`

3. Group Management: Create a group named `mambaforge` and give it access to the installation.

```
sudo groupadd mambaforge
sudo chgrp -R mambaforge /opt/mambaforge
```

4. Adjust Permissions: Make sure the group has read, write, and execute permissions to the `mambaforge` directory. This allows any member of the group to install and modify packages.

```
sudo chmod 777 -R /opt/mambaforge
sudo chmod 777 -R /opt/mambaforge/share
sudo chown -R :mambaforge /opt/mambaforge/share
```

5. Add Users to the Group: If you have specific users in mind, replace user with their username. This adds them to the `mambaforge` group.

`sudo adduser user mambaforge`

6. Set User Profile: Each user, upon login, should activate `mambaforge`. This can be done by sourcing the activate script and then initializing `conda` for their shell.

```
source /opt/mambaforge/bin/activate
mamba init
```

7. Set Cache Permissions: To ensure that all files created in the cache directory are accessible by all users in the `mambaforge` group:

```
sudo chown :mambaforge /opt/mambaforge/pkgs/cache/
sudo chmod g+s /opt/mambaforge/pkgs/cache/
```

* Permission problem insistence would prevent installation.

`sudo rm -rf /opt/mambaforge/pkgs/cache/`

8. Clean Up: Remove the installer script.

`rm Mambaforge-Linux-x86_64.sh`

# Nextflow

## `nextflow` for multiple users

Start with Java 17 installation by `sudo apt install openjdk-17-source`. Download and install nextflow `curl -fsSL get.nextflow.io | bash` then `sudo mv nextflow /usr/local/bin`.

Change the group of users to the group that all users are assigned to by `sudo chown admin:users /usr/local/bin/nextflow` then `sudo chmod 777 /usr/local/bin/nextflow`. 

Now `sudo nano /etc/bash.bashrc` and add the following line `export PATH="/usr/local/bin/:$PATH"`.

## Run `nextflow` pipeline locally

1) Download Necessary Files:

    * Download all required datasets, databases, and the private key.

    * Ensure the private key is named *_accessKeys.csv and has the following format:

        |Access key ID|Secret access key|
        |---|---|
        |AKIAR***************|SVF+************************************|

2) Configuration Adjustments:

    * Modify the `design.csv` file as required.

    * Update the `conf/igenomes.config` file with appropriate configurations.

    * Tweak the number of cores/threads and RAM settings in `conf/base.config` to align with your machine's capabilities or your performance requirements.

3) Install Required Tools:

    * To enable Docker to pull images from AWS, you'll need the amazon-ecr-credential-helper. Install it using: `sudo apt install amazon-ecr-credential-helper`.

    * Set up AWS credentials by running aws configure and provide the details from the `accessKeys.csv` when prompted.

4) Configure Docker for AWS ECR Access:

    * Create a Docker configuration directory if it doesn't exist: `mkdir -p ~/.docker`.
 
    * Update the Docker configuration to use ECR login credentials by appending `{"credsStore": "ecr-login"}` to the `~/.docker/config.json` file.

5) Docker Image Handling:

    * Pull the specific Docker image from AWS using:

    `docker pull **********.dkr.ecr.us-east-1.amazonaws.com/******:2.2.1`

    * If you need to build a new Docker image locally, navigate to the directory containing the Dockerfile and run: `docker build .`

    * Verify the image has been built or pulled correctly using: `docker images`. **Note down the image ID for the next steps.**

6) Adjust Nextflow Image Configuration: 
  
    * Once you've got the Docker image, if you're running Nextflow locally, you need to update the `process.container` directive in your Nextflow configuration to use the correct image ID. Also, ensure you're adding `-with-docker` as a parameter when initiating a Nextflow run.

7) Running the workflow:

With everything set up, you're now ready to execute the Nextflow workflow:

```
nextflow run main.nf \
        -profile docker \
        -work-dir workdir \
        --awsregion us-west-2 \
        --genome ****** \
        --design design.csv \
        --outdir results \
        --protocol ****** \
        --name ****** \
        --maxMemory 120.GB
```

# `termux` set up

Install necessary packages

```
pkg update && \
pkg upgrade -y && \
pkg autoclean && \
pkg clean && \
pkg install curl wget git zip unzip gawk nano eza ripgrep htop ruby openssh zsh tmux tree python3 nmap jq pup bat aria2 fzf entr && \
gem install lolcat
```

Set up `Oh-My-Zsh`

```
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
chsh -s $(which zsh) && \
git clone https://github.com/adi1090x/termux-style && \
cd termux-style && \
./install
```

Improve `zsh`

```
echo -e 'export ZSH="$HOME/.oh-my-zsh"\nZSH_THEME="junkfood"\nplugins=(git z zsh-autosuggestions zsh-syntax-highlighting)\nsource $ZSH/oh-my-zsh.sh\nalias ll="ls -l"\nalias la="ls -A"\nHISTSIZE=10000\nSAVEHIST=10000\nsetopt appendhistory\nsetopt sharehistory\nzstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"\nsetopt correct' > $HOME/.zshrc && \
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
echo "source $HOME/.zshrc" > $HOME/.zprofile && \
sleep 1 && \
logout
```

Add more keys to the extra keys by:

```
mkdir -p $HOME/.termux && \
echo "extra-keys = [['ESC', 'TAB', 'CTRL', 'ALT', 'SHIFT', 'DEL', 'BACKSLASH', 'KEYBOARD'], ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'HOME', 'PGUP'], ['F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'END', 'PGDN'], ['LEFT', 'UP', 'DOWN', 'RIGHT', '/', '|', 'QUOTE', 'APOSTROPHE']]" >> $HOME/.termux/termux.properties && \
termux-reload-settings && \
sleep 1 && \
logout
```

Use `termux-setup-storage` to get permission for storage.

Codespace style prompt:

`nano /data/data/com.termux/files/usr/etc/bash.bashrc`

```
function __setprompt() {
    local exit_status=$?
    local arrow_color="\[\033[1;37m\]"
    local conda_env="\[\033[1;33m\]$CONDA_DEFAULT_ENV\[\033[1;33m\]"
    local git_branch=""

    if [[ $exit_status != 0 ]]; then
        arrow_color="\[\033[1;31m\]"
    fi

    if command -v git &>/dev/null; then
        git_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    fi

    if [[ ! -z $git_branch ]]; then
        git_branch="\[\033[1;33m\]${git_branch}\[\033[1;33m\]"
    fi

    if [[ $conda_env != "" && $git_branch != "" ]]; then
        env_branch="\[\033[0;37m\](${conda_env}\[\033[0;37m\]:${git_branch}\[\033[0;37m\])"
    else
        env_branch="\[\033[0;37m\](${conda_env}${git_branch}\[\033[0;37m\])"
    fi

    PS1="\[\033[0;32m\]\u@\h ${arrow_color}➜ \[\033[1;34m\]\w ${env_branch} \[\033[1;37m\]$ \[\033[00m\]"
}

PROMPT_COMMAND="__setprompt; $PROMPT_COMMAND"
```

# Misc.

* Install brew without `sudo`: `mkdir brew; curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C ~/brew; eval "$(~/brew/bin/brew shellenv)"; brew update --force --quiet`

* Create fake 5 TB file: `fallocate -l 5T testfile.txt`.

* How to reset git commits to the very beginning.

  1) Clone your repo.

  2) Reset to the very beginning: `git reset $(git rev-list --max-parents=0 HEAD)`.

  3) Squash all commits.

  ```
  git add -A
  git commit -m "<new commit message for the squashed commit>"
  ```

  4) Force push it back to the desired branch: `git push origin <branch-name> --force`.

* Fast download with aria2c: `aria2c  https://ftp.ensembl.org/pub/release-110/variation/indexed_vep_cache/homo_sapiens_merged_vep_110_GRCh38.tar.gz  -x 8 -s 16 -j 3 &`.

* Use `whereis` to look for binary executable.

* Use `link` to create hard link. `stat -c %h <file>` to check whether a file is a hard link.

* Format and mount new drive.

  1) Start parted: `sudo parted /dev/sda`.

  2) Create new partition table: `mklabel gpt`.

  3) Create partition: `mkpart primary ext4 0% 100%`.
 
  4) Format: `sudo mkfs.ext4 /dev/sda1`.

  5) Create new mount point: `sudo mkdir /mnt/d4t`.

  6) Mount formatted partition: `sudo mount /dev/sda1 /mnt/d4t`.

* Essential tools:

  ```
  brew install curl aria2 git zip unzip gawk fish openssh-server tmux nmap jq eza ripgrep bat fzf mc zoxide entr
  ```

  To install Python3 under linuxbrew, follow below steps before install it:
    
    * Install `util-linux` with `brew install util-linux` or reinstall it with `brew reinstall util-linux`
      
    * Create a symbolic link for `uuid.h` which is usually missing if brew is installed without `sudo`: `ln -s "$(brew --prefix util-linux)/include/uuid/uuid.h" "$(brew --prefix)/include/uuid.h"`

  Add `eval "$(zoxide init bash)"` to the `.bashrc` to initialize `zoxide`.

* Increase swap.

  ```
  sudo fallocate -l 16G /swapfile \
  sudo chmod 600 /swapfile \
  sudo mkswap /swapfile \
  sudo swapon /swapfile
  ```

  Check with `sudo swapon --show`

* Clone the whole GitHub organization.

   ```
   gh repo list <your_org_name> --limit 1000 | while read -r repo _; do
      gh repo clone $repo $repo -- -q 2>/dev/null || ( 
         cd $repo
          # Handle case where local checkout is on a non-main/master branch
          # - ignore checkout errors because some repos may have zero commits, 
          # so no main or master
          git checkout -q main 2>/dev/null || true
          git checkout -q master 2>/dev/null || true
          git pull -q
      ) 
   done
   
   # For faster cloning, use xargs with this
   gh repo list <your_org_name> --limit <limit> --json nameWithOwner --jq '.[].nameWithOwner' | \
      xargs -I {} -P <threads> bash -c 'gh repo {}'
   
   # Keep in mind that there's a limit of 4,000 repos each page
   ```

* Wait for a process to finish and do something.

```
ps aux | grep <command>

while ps -p <pid> > /dev/null; do sleep 1; done && <command>
```

* Swap Ctrl and Caps: `sudo nano /etc/default/keyboard` and add `XKBOPTIONS="ctrl:nocaps"`.

* Increase limits for `Too many open files` error:

  * Check limit with `ulimit -n`, then increase with `ulimit -n <limit>`
 
  * For permanent setting:
      
      * Edit `/etc/security/limits.conf` and add this to the end:
      
        ```
        * soft nofile 4096
        * hard nofile 4096
        ```

      * Edit `/etc/pam.d/common-session` and `/etc/pam.d/common-session-noninteractive` and add this to the end:
   
        ```
        session required pam_limits.so
        ```

# Start a script at system booting up

  1. Create a systemd service unit file: `sudo nano /etc/systemd/system/my-script.service`

  2. Add the following content to the service unit file:

  ```
  [Unit]
  Description=My Script Service
  After=network.target

  [Service]
  ExecStart=/path/to/your/script.sh
  Restart=always
  User=your_username  # Modify this to your sudoer

  [Install]
  WantedBy=multi-user.target
  ```

  3. Save and reload systemd: `sudo systemctl daemon-reload`

  4. Enable the service: `sudo systemctl enable my-script.service`

  5. Start the service: `sudo systemctl start my-script.service`

# Upload to cloud from terminal

`sudo apt install rclone && rclone config`

# Create encrypted dir

1) Install `gocryptfs`: `sudo apt-get install gocryptfs`.

2) Create a new dir for encrypted content: `mkdir ~/encrypted_directory`.

3) Initialize the encrypted dir: `gocryptfs -init ~/encrypted_directory`. During initialization, you'll be prompted to set a password.

4) Mount the encrypted dir: `gocryptfs ~/encrypted_directory ~/mounted_directory`. Replace ~/mounted_directory with the path where you want to access your decrypted files. Now, you can copy/move your files into the `mounted_directory`, and they will be automatically encrypted in the `encrypted_directory`.

5) When you're done working with your files, unmount the encrypted dir: `fusermount -u ~/mounted_directory`.

# Prevent computer from going sleep

```
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```

# CLI to send email

* Install `msmtp` and `mailutils`: `sudo apt install mailutils msmtp`

* Go to [Google Account](https://myaccount.google.com/) and search for `App passwords` to create one. Remember to turn on 2-step verification since App passwords require this. 

* Copy the following into `.msmtprc` with `nano ~/.msmtprc`:

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
password fkuw njim vohk grvs # Replace this with the one from App passwords
from your@gmail.com
```

* Try sending a test email with: `echo "This is a test email" | msmtp -a gmail your@gmail.com`

# VSCode 

* Override default keybindings to use bash shortcuts

```
// Place your key bindings in this file to override the defaults
[
    {
        "key": "ctrl+e",
        "command": "ctrl+e",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+a",
        "command": "ctrl+a",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+x",
        "command": "ctrl+x",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+s",
        "command": "ctrl+s",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+b",
        "command": "ctrl+b",
        "when": "terminalFocus"
    },
]
```

# GitHub

## Process to control access to private repositories between two organizations

1) Ownership Requirement: The owner of the first organization must also be the owner of the second organization. This ensures that the same entity controls both organizations.

2) Enable Repository Forking: Turn on the option to allow forking of private repositories. This setting enables users to fork private repositories from one organization to another.

3) Forking Private Repositories: The owner, who controls both organizations, initiates the process of forking private repositories from the first organization to the second organization. This allows the owner to maintain control over the repositories being transferred.

4) Adding Users to the Second Organization: After forking the repositories, the owner adds users to the second organization. These users are granted access to view the forked private repositories in the second organization without being able to access or view the private repositories of the first organization. This step ensures that access to sensitive information is limited only to authorized individuals within the second organization.PRJNA637390
