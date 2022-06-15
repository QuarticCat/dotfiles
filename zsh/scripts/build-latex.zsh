#!/bin/zsh

set -e

# -------------------------------- Config Begin --------------------------------

# parent directory of temporary directories
CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/latex-build

# --------------------------------- Config End ---------------------------------

tex_cmd=$1
job_name=$2
doc_dir=$PWD
cache_dir=$CACHE_DIR/${PWD//\//@}  # replace all '/' with '@'

mkdir -p $cache_dir
cp -rlf $doc_dir/* $cache_dir

cd $cache_dir
$=tex_cmd $doc_dir/$job_name
cp -lf $job_name.pdf $job_name.synctex.gz $doc_dir
