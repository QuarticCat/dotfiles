#!/usr/bin/zsh

DOT=${0:a:h}  # the directory of this script

declare -A pf_map

_add-pf() { pf_map[${2%.*}]+="$1 $3 $4 " }
alias -s pf="_add-pf self"
alias -s rpf="_add-pf root"

_rsync-pf() {  # sync|apply <pf-name>
    setopt extended_glob
    for own loc pat in $=pf_map[$2]; case $1-$own {
        (sync-*)          rsync $rsync_opts -R $loc/./$~pat $DOT/$2/ ;;
        (apply-self)      rsync $rsync_opts -R $DOT/$2/./$~pat $loc/ ;;
        (apply-root) sudo rsync $rsync_opts -R $DOT/$2/./$~pat $loc/ ;;
    }
}

_rsync-each-pf() {  # sync|apply [--all|<pf-name>...]
    [[ $2 == --all ]] && set -- $1 ${(k)pf_map}
    source env_parallel.zsh
    [[ $1 == apply ]] && sudo true  # refresh cache
    env_parallel --ctag "_rsync-pf $1" ::: ${@:2}
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

plasma.pf ~/.config      'fcitx5|*-flags.conf'
plasma.pf ~/.config      '(konsole|yakuake|ktrash|kio)rc'
plasma.pf ~/.local/share 'konsole/qc-*.profile'
plasma.pf ~/.local/share 'applications/*.desktop'

clang-format.pf ~ '.clang-format'

cargo.pf   ~/.cargo              'config.toml'
gpg.pf     ~/.gnupg              'gpg-agent.conf'
ipython.pf ~/.ipython/profile_qc 'ipython_config.py'
ssh.pf     ~/.ssh                'config'

atuin.pf      ~/.config/atuin      '*'
clangd.pf     ~/.config/clangd     '*'
containers.pf ~/.config/containers '*'
direnv.pf     ~/.config/direnv     '*'
discord.pf    ~/.config/discord    'settings.json'
fastfetch.pf  ~/.config/fastfetch  '*'
fontconfig.pf ~/.config/fontconfig '*'
ghc.pf        ~/.config/ghc        'ghci.conf'
git.pf        ~/.config/git        '*'
mpv.pf        ~/.config/mpv        '*'
nvim.pf       ~/.config/nvim       '*'
paru.pf       ~/.config/paru       '*'
tealdeer.pf   ~/.config/tealdeer   '*'
thefuck.pf    ~/.config/thefuck    '^__pycache__'
zellij.pf     ~/.config/zellij     '*'

btrbk.rpf  /etc/btrbk/              'btrbk.conf'
pacman.rpf /etc                     'pacman.conf'
pacman.rpf /etc/pacman.d            'mirrorlist'
pacman.rpf /usr/share/libalpm/hooks 'qc-*.hook'
sshd.rpf   /etc/ssh/sshd_config.d   'qc-*.conf'
udev.rpf   /etc/udev/rules.d        'qc-*.rules'

# ================================ Config End ================================ #

_rsync-each-pf $@
