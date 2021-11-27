#!/bin/zsh

setopt null_glob extended_glob no_bare_glob_qual

CYAN='\033[0;36m'
NC='\033[0m'  # No Color

DOT_DIR=${0:a:h}  # the directory of this script

pf_loc=()  # profile locations
pf_pat=()  # profile patterns

declare -A pf_map   # <pf-name> : <idxes> (e.g. ' 1 2 3')
declare -A enc_map  # <pf-name> : <pat>

_add-pf() {  # <pf-name> {<pf-loc> <pf-pat>}...
    local name=${1%.pf}
    for i in {2..$#@..2}; {
        pf_loc+=($@[i])
        pf_pat+=($@[i+1])
        pf_map[$name]+=" $#pf_loc"
    }
}
alias -s pf='_add-pf'

_add-enc() {  # <pf-name> <pat>
    local name=${1%.enc}
    enc_map[$name]=$2
}
alias -s enc='_add-enc'

_rsync-pat() {  # <src> <dst> <pat>
    cd $1 &>/dev/null &&
    rsync $=rsync_opt -R $~=3 $2/
}

_sync() {  # <pf-name>
    for i in ${=pf_map[$1]:1}; {
        echo $CYAN"$1 <- ${(D)pf_loc[i]}"$NC
        _rsync-pat $pf_loc[i] $DOT_DIR/$1 $pf_pat[i]
        echo
    }
}

_apply() {  # <pf-name>
    for i in ${=pf_map[$1]:1}; {
        echo $CYAN"$1 -> ${(D)pf_loc[i]}"$NC
        _rsync-pat $DOT_DIR/$1 $pf_loc[i] $pf_pat[i]
        echo
    }
}

_gpg-pat() {  # <gpg-opt> <dir> <pat>
    cd $2 &>/dev/null &&
    for f in $~=3; {
        [[ -f $f ]] &&
        gpg $=1 -o $f.temp $f &&
        mv -f $f.temp $f
    }
}

_encrypt() {  # <pf-name>
    _gpg-pat "-e -r $gpg_rcpt" $DOT_DIR/$1 $enc_map[$1]
}

_decrypt() {  # <pf-name>
    _gpg-pat "-d -q" $DOT_DIR/$1 $enc_map[$1]
}

_complete_sync() {  # <pf-name>
    _decrypt $1 && _sync $1 && _encrypt $1
}

_complete_apply() {  # <pf-name>
    _decrypt $1 && _apply $1 && _encrypt $1
}

_for-each-pf() {  # <func> {'--all'|<pf-name>...}
    local func=$1; shift
    if [[ $1 == --all ]] {
        for i in ${(k)pf_map}; $func $i
    } else {
        for i in ${(u)@}; [[ -v pf_map[$i] ]] && $func $i
    }
}

cute-dot-list()  { printf '%s\n' ${(ko)pf_map} }
cute-dot-sync()  { _for-each-pf _complete_sync $@ }
cute-dot-apply() { _for-each-pf _complete_apply $@ }

# -------------------------------- Config Begin --------------------------------

rsync_opt='-ri'  # rsync options

gpg_rcpt='QuarticCat'  # gpg recipient

# profile list

zsh.pf \
    ~ '.zshenv' \
    ~/.config/zsh '.zshrc *.zsh (^.*)/(^*.zwc)'

ssh.pf \
    ~/.ssh 'config*'
ssh.enc 'config-private'

git.pf \
    ~ '.gitconfig'

proxychains.pf \
    ~/.proxychains 'proxychains.conf'

cargo.pf \
    ~/.cargo 'config.toml' \
    ~/.config 'user-tmpfiles.d/cargo.conf'

ghc.pf \
    ~/.ghc 'ghci.conf'

stack.pf \
    ~/.stack 'config.yaml' \
    ~/.config 'user-tmpfiles.d/stack.conf'

pip.pf \
    ~/.config/pip 'pip.conf'

ipython.pf \
    ~/.ipython/profile_default 'ipython_config.py'

direnv.pf \
    ~/.config/direnv 'direnvrc'

fontconfig.pf \
    ~/.config/fontconfig 'fonts.conf'

pacman.pf \
    /etc 'pacman.conf'

paru.pf \
    ~/.config/paru 'paru.conf'

docker.pf \
    /etc/docker 'daemon.json'

# --------------------------------- Config End ---------------------------------

cute-dot-$1 ${@:2}
