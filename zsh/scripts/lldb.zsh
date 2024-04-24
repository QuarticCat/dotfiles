#!/bin/zsh

# Ref: https://github.com/vadimcn/vscode-lldb/blob/master/MANUAL.md

setopt extended_glob

prog="'$commands[$1]'"  # expand to `'/path/to/program'`
args=("'${^@:2}'")      # expand to `'arg1' 'arg2' ...`

# Ref: https://gist.github.com/lucasad/6474224
chars=(${(s::):-"$prog $args"})
encoded=${(j::)chars/(#m)[^ \/A-Za-z0-9_.\!~*\'\(\)-]/%${(l:2::0:)$(([##16]#MATCH))}}

code --open-url "vscode://vadimcn.vscode-lldb/launch/command?$encoded"
