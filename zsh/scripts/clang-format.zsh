#!/usr/bin/zsh

file=$1

sd '#pragma' '// #pragma' $file
clang-format -i $file
sd '// #pragma' '#pragma' $file
