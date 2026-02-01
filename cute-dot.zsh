#!/bin/zsh

DOT=${0:a:h}  # the directory of this script

declare -A pf_map

_add-pf() { pf_map[${2%.*}]+="$1 $3 $4 " }
alias -s pf="_add-pf self"
alias -s rpf="_add-pf root"

_rsync-pf() {  # sync|apply <pf-name>
    setopt extended_glob
    local output=$(for own loc pat in $=pf_map[$2]; case $1-$own {
        (sync-*)          rsync $rsync_opts -R $loc/./$~pat $DOT/$2/ ;;
        (apply-self)      rsync $rsync_opts -R $DOT/$2/./$~pat $loc/ ;;
        (apply-root) sudo rsync $rsync_opts -R $DOT/$2/./$~pat $loc/ ;;
    })
    [[ $output != '' ]] && printf "\e[1m\e[33m$2\e[0m\n$output\n"
}

_rsync-each-pf() {  # sync|apply [--all|<pf-name>...]
    [[ $2 == --all ]] && set -- $1 ${(k)pf_map}
    [[ $1 == apply ]] && sudo -v
    autoload -Uz zargs
    zargs -P0 -l1 -- ${@:2} -- _rsync-pf $1
}

# =============================== Config Begin =============================== #

rsync_opts=(
    # --dry-run
    --recursive
    --mkpath
    --checksum
    --itemize-changes
)

zsh.pf ~             '.zshenv'
zsh.pf ~/.config/zsh '.zshrc|^*.zwc'

bun.pf          ~ '.bunfig.toml'
clang-tidy.pf   ~ '.clang-tidy'
clang-format.pf ~ '.clang-format'
npm.pf          ~ '.npmrc'

cargo.pf   ~/.cargo              'config.toml'
gpg.pf     ~/.gnupg              'gpg-agent.conf'
ipython.pf ~/.ipython/profile_qc 'ipython_config.py'
ssh.pf     ~/.ssh                'config'

atuin.pf     ~/.config/atuin     '*'
bat.pf       ~/.config/bat       '*'
ccache.pf    ~/.config/ccache    '*'
clangd.pf    ~/.config/clangd    '*'
fastfetch.pf ~/.config/fastfetch '*'
ghc.pf       ~/.config/ghc       'ghci.conf'
git.pf       ~/.config/git       '*'
htop.pf      ~/.config/htop      '*'
uv.pf        ~/.config/uv        '*'
yazi.pf      ~/.config/yazi      '*'

if [[ $OSTYPE == linux* ]] {
    plasma.pf ~/.config      '*-flags.conf'
    plasma.pf ~/.config      '(konsole|yakuake|ktrash|kio|kcminput)rc'
    plasma.pf ~/.local/share 'konsole/qc-*.profile'
    plasma.pf ~/.local/share 'applications/discord.desktop'

    systemd.pf ~/.config/systemd 'user/qc-*'

    containers.pf ~/.config/containers '*'
    fontconfig.pf ~/.config/fontconfig '*'
    mpv.pf        ~/.config/mpv        '*'
    paru.pf       ~/.config/paru       '*'

    btrbk.rpf  /etc/btrbk             'btrbk.conf'
    pacman.rpf /etc/pacman.d          'hooks'
    sshd.rpf   /etc/ssh/sshd_config.d 'qc-*.conf'
    udev.rpf   /etc/udev/rules.d      'qc-*.rules'
}

# ================================ Config End ================================ #

_rsync-each-pf $@
