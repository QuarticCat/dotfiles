#!/bin/zsh

setopt null_glob extended_glob no_bare_glob_qual

CYAN='\033[0;36m'
NC='\033[0m'  # No Color

DOT_DIR=${0:a:h}  # the directory of this script

pf_name=()  # array of profile names
pf_loc=()   # array of profile locations
pf_pat=()   # array of profile patterns

declare -A enc_pat  # associative array of encrypt patterns

_add-pf() {
    local name=${1%.pf}
    for i in {2..$#@..2}; {
        pf_name+=($name)
        pf_loc+=($@[i])
        pf_pat+=($@[i+1])
    }
}
alias -s pf='_add-pf'

_add-enc() {
    local name=${1%.enc}
    enc_pat[$name]=$2
}
alias -s enc='_add-enc'

_sync() {
    echo $CYAN"$pf_name[$1] <- ${(D)pf_loc[$1]}"$NC
    local dst=$DOT_DIR/$pf_name[$1]
    local src=$pf_loc[$1]
    local pat=(${(s/;/)pf_pat[$1]})
    cd $src && rsync $=rsync_opt -R $~=pat $dst/
    echo
}

_apply() {
    echo $CYAN"$pf_name[$1] -> ${(D)pf_loc[$1]}"$NC
    local dst=$DOT_DIR/$pf_name[$1]
    local src=$pf_loc[$1]
    local pat=(${(s/;/)pf_pat[$1]})
    cd $dst && rsync $=rsync_opt -R $~=pat $src/
    echo
}

_encrypt() {
    local name=$1
    local pat=(${(s/;/)enc_pat[$1]})
    cd $DOT_DIR/$name &>/dev/null &&
    for f in $~=pat; {
        [[ -f $f ]] &&
        gpg -e -r $gpg_rcpt $f &&
        rm $f
    }
}

_decrypt() {
    local name=$1
    local pat=(${(s/;/)enc_pat[$1]})
    cd $DOT_DIR/$name &>/dev/null &&
    for f in $~^=pat.gpg; {
        [[ -f $f ]] &&
        gpg -d -o ${f%.gpg} $f &&
        rm $f
    }
}

_for-each-pf() {
    local func=$1; shift
    if [[ $1 == --all ]] {
        for n in ${(k)enc_pat}; _decrypt $n
        for i in {1..$#pf_name}; $func $i
        for n in ${(k)enc_pat}; _encrypt $n
    } else {
        for n in $@; [[ -v enc_pat[$n] ]] && _decrypt $n
        for i in {1..$#pf_name}; (( $@[(Ie)$pf_name[i]] )) && $func $i
        for n in $@; [[ -v enc_pat[$n] ]] && _encrypt $n
    }
}

profile-list()  { printf '%s\n' ${(u)pf_name} }
profile-sync()  { _for-each-pf _sync $@ }
profile-apply() { _for-each-pf _apply $@ }

# -------------------------------- Config Begin --------------------------------

rsync_opt='-ri'  # rsync options

gpg_rcpt='QuarticCat'  # gpg recipient

# profile list

zsh.pf \
    ~ '.zshenv' \
    ~/.config/zsh '.zshrc; *.zsh; (^.*)/(^*.zwc)'

ssh.pf \
    ~/.ssh 'config*'
ssh.enc 'config-private'

git.pf \
    ~ '.gitconfig'

cargo.pf \
    ~/.cargo 'config.toml' \
    ~/.config 'user-tmpfiles.d/cargo.conf'

ghc.pf \
    ~/.ghc 'ghci.conf'

stack.pf \
    ~/.stack 'config.yaml' \
    ~/.config 'user-tmpfiles.d/stack.conf'

ipython.pf \
    ~/.ipython/profile_default 'ipython_config.py'

proxychains.pf \
    ~/.proxychains 'proxychains.conf'

direnv.pf \
    ~/.config/direnv 'direnvrc'

fontconfig.pf \
    ~/.config/fontconfig 'fonts.conf'

paru.pf \
    ~/.config/paru 'paru.conf'

pip.pf \
    ~/.config/pip 'pip.conf'

pacman.pf \
    /etc 'pacman.conf'

docker.pf \
    /etc/docker 'daemon.json'

# --------------------------------- Config End ---------------------------------

profile-$1 ${@:2}
