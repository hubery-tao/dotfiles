#!/bin/bash

curr_dir=$(dirname ${BASH_SOURCE[0]})
cp ${curr_dir%/}/.vimrc $HOME
cp ${curr_dir%/}/.tmux.conf $HOME

mkdir -p $HOME/.bashrc.d
cp -ru ${curr_dir%/}/.bashrc.d/* $HOME/.bashrc.d
cat <<EOF >> $HOME/.bashrc

if [ -d ~/.bashrc.d ]; then
    for file in ~/.bashrc.d/*.sh; do
        source $file
    done
fi
EOF
