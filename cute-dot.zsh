#!/bin/zsh

DOT_DIR=${0:a:h}  # the directory of this script

pf_loc=()  # profile locations
pf_pat=()  # profile patterns
declare -A pf_map  # <pf-name> : <idxes>

_add-pf() {  # <pf-name>.pf <pf-loc> <pf-pat>
    pf_loc+=($2)
    pf_pat+=($3)
    pf_map[${1%.pf}]+="$#pf_loc "
}
alias -s pf=_add-pf

_rsync-pf() {  # [← | →] <pf-name>
    setopt extended_glob
    for i in $=pf_map[$2]; case $1 {
        (←) rsync $rsync_opts -R $pf_loc[i]/./$~pf_pat[i] $DOT_DIR/$2/ ;;
        (→) rsync $rsync_opts -R $DOT_DIR/$2/./$~pf_pat[i] $pf_loc[i]/ ;;
    }
}

_rsync-each-pf() {  # [← | →] [--all | <pf-name>...]
    [[ $2 == --all ]] && set -- $1 ${(k)pf_map}
    source env_parallel.zsh
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

# ================================ Config End ================================ #

cute-dot-$1 ${@:2}
