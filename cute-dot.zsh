#!/bin/zsh

DOT=${0:a:h}  # the directory of this script

declare -A pf_map

_add-pf() { pf_map[${2%.*}]+="$1 $3 $4 " }
alias -s pf="_add-pf $USER"
alias -s rpf="_add-pf root"

_rsync-pf() {  # ←|→ <pf-name>
    setopt extended_glob
    for own loc pat in $=pf_map[$2]; case $1@$own {
        (←@*)          rsync $rsync_opts -R $loc/./$~pat $DOT/$2/ ;;
        (→@$USER)      rsync $rsync_opts -R $DOT/$2/./$~pat $loc/ ;;
        (→@root)  sudo rsync $rsync_opts -R $DOT/$2/./$~pat $loc/ ;;
    }
}

_rsync-each-pf() {  # ←|→ [--all|<pf-name>...]
    [[ $2 == --all ]] && set -- $1 ${(k)pf_map}
    source env_parallel.zsh
    sudo true  # refresh cache
    env_parallel --ctag "_rsync-pf $1" ::: ${@:2}
}

cute-dot-sync()  { _rsync-each-pf ← $@ }
cute-dot-apply() { _rsync-each-pf → $@ }

# =============================== Config Begin =============================== #

rsync_opts=(
    # --dry-run
    --recursive
    --mkpath
    --checksum
    --itemize-changes
)

zsh.pf ~             '.zshenv'
zsh.pf ~/.config/zsh '(.zshrc|^*.zwc)'

clang-format.pf ~ '.clang-format'
npm.pf          ~ '.npmrc'

cargo.pf   ~/.cargo              'config.toml'
gpg.pf     ~/.gnupg              'gpg-agent.conf'
ipython.pf ~/.ipython/profile_qc 'ipython_config.py'
ssh.pf     ~/.ssh                'config'

atuin.pf      ~/.config/atuin      '*'
clangd.pf     ~/.config/clangd     '*'
containers.pf ~/.config/containers '*'
direnv.pf     ~/.config/direnv     '*'
fontconfig.pf ~/.config/fontconfig '*'
ghc.pf        ~/.config/ghc        'ghci.conf'
git.pf        ~/.config/git        '*'
mpv.pf        ~/.config/mpv        '*'
paru.pf       ~/.config/paru       '*'
tealdeer.pf   ~/.config/tealdeer   '*'
thefuck.pf    ~/.config/thefuck    '^__pycache__'
zellij.pf     ~/.config/zellij     '*'

wayland.pf ~/.config '(code|microsoft-edge-*)-flags.conf'

btrbk.rpf  /etc/btrbk/              'btrbk.conf'
pacman.rpf /etc                     'pacman.conf'
pacman.rpf /etc/pacman.d            'mirrorlist'
pacman.rpf /usr/share/libalpm/hooks 'qc-*.hook'
sshd.rpf   /etc/ssh                 'sshd_config'
udev.rpf   /etc/udev/rules.d        '(10-uas-discard|69-canokeys).rules'

# ================================ Config End ================================ #

cute-dot-$1 ${@:2}
