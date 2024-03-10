#!/bin/zsh

DOT_DIR=${0:a:h}  # the directory of this script

pf_loc=()  # profile locations
pf_pat=()  # profile patterns
declare -A pf_map  # <pf-name> : <idxes>

_add-pf() {  # <pf-name> {<pf-loc> <pf-pat>}...
    local name=${1%.pf}
    for loc pat in ${@:2}; {
        pf_loc+=($loc)
        pf_pat+=($pat)
        pf_map[$name]+="$#pf_loc "
    }
}
alias -s pf='_add-pf'

_rsync-pat() {  # <src> <dst> <pat>
    cd $1 && rsync $rsync_opt --relative $~=3 $2/
}

_sync() {  # <pf-name>
    for i in $=pf_map[$1]; {
        local changes=$(_rsync-pat $pf_loc[i] $DOT_DIR/$1 $pf_pat[i])
        [[ $changes == '' ]] && continue
        echo $fg[cyan]"$1 <- ${(D)pf_loc[i]}"$reset_color
        echo $changes$'\n'
    }
}

_apply() {  # <pf-name>
    for i in $=pf_map[$1]; {
        local changes=$(_rsync-pat $DOT_DIR/$1 $pf_loc[i] $pf_pat[i])
        [[ $changes == '' ]] && continue
        echo $fg[cyan]"$1 -> ${(D)pf_loc[i]}"$reset_color
        echo $changes$'\n'
    }
}

source $(which env_parallel.zsh)

_init() {
    setopt null_glob extended_glob
    autoload -Uz colors && colors
}

_for-each-pf() {  # <func> [--all | <pf-name>...]
    if [[ $2 == --all ]] {
        env_parallel "_init; $1" ::: ${(k)pf_map}
    } else {
        env_parallel "_init; $1" ::: ${(u)@:2}
    }
}

cute-dot-list()  { printf '%s\n' ${(ko)pf_map} }
cute-dot-sync()  { _for-each-pf _sync $@ }
cute-dot-apply() { _for-each-pf _apply $@ }

# =============================== Config Begin =============================== #

rsync_opt=(
    # '--dry-run'
    '--recursive'
    '--mkpath'
    '--checksum'
    '--itemize-changes'
)

zsh.pf \
    ~ '.zshenv' \
    ~/.config/zsh '.zshrc *.zsh */^*.zwc'

podman.pf \
    ~/.config/containers '*'

gpg.pf \
    ~/.gnupg 'gpg-agent.conf'

ssh.pf \
    ~/.ssh 'config'

git.pf \
    ~/.config/git '*'

proxychains.pf \
    ~/.proxychains 'proxychains.conf'

cargo.pf \
    ~/.cargo 'config.toml'

ghc.pf \
    ~/.ghc 'ghci.conf'

pip.pf \
    ~/.config/pip '*'

ipython.pf \
    ~/.ipython/profile_default 'ipython_config.py'

thefuck.pf \
    ~/.config/thefuck '^__pycache__'

direnv.pf \
    ~/.config/direnv '*'

atuin.pf \
    ~/.config/atuin '*'

tealdeer.pf \
    ~/.config/tealdeer '*'

zellij.pf \
    ~/.config/zellij '*'

fontconfig.pf \
    ~/.config/fontconfig '*'

paru.pf \
    ~/.config/paru '*'

clang/clang-format.pf \
    ~ '.clang-format'

clang/clangd.pf \
    ~/.config/clangd '*'

npm.pf \
    ~ '.npmrc'

mpv.pf \
    ~/.config/mpv '*'

wayland.pf \
    ~/.config '(code|microsoft-edge-stable)-flags.conf'

# ================================ Config End ================================ #

cute-dot-$1 ${@:2}
