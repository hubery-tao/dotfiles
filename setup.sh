#!/bin/bash

curr_dir=$(dirname ${BASH_SOURCE[0]})
curr_dir=$(realpath $curr_dir)
curr_dir=${curr_dir%/}

ln -sf $curr_dir/.vimrc $HOME/.vimrc
ln -sf $curr_dir/.tmux.conf $HOME/.tmux.conf

mkdir -p $HOME/.bashrc.d
for script in $curr_dir/.bashrc.d/*; do
    name=$(basename $script)
    ln -sf $curr_dir/.bashrc.d/$name $HOME/.bashrc.d/$name
done
cat <<'EOF' >> $HOME/.bashrc

if [ -d ~/.bashrc.d ]; then
    for file in ~/.bashrc.d/*.sh; do
        source $file
    done
fi
EOF

rm -rf $HOME/.config/nvim
ln -sf $curr_dir/.config/nvim $HOME/.config/nvim
