#!/bin/bash

uname_out=$(uname)
if [[ $uname_out == "Darwin" ]]; then
	shellrc=".zshrc"
	shellrcd=".zshrc.d"
elif [[ $uname_out == "Linux" ]]; then
	shellrc=".bashrc"
	shellrcd=".bashrc.d"
else
	echo "Error: System not Linux or MacOS"
	exit 1
fi

curr_dir=$(dirname ${BASH_SOURCE[0]})
curr_dir=$(realpath $curr_dir)
curr_dir=${curr_dir%/}

ln -sf $curr_dir/.vimrc $HOME/.vimrc
ln -sf $curr_dir/.tmux.conf $HOME/.tmux.conf

mkdir -p $HOME/$shellrcd
for script in $curr_dir/.bashrc.d/*; do
    name=$(basename $script)
    ln -sf $curr_dir/.bashrc.d/$name $HOME/$shellrcd/$name
done
cat <<EOF >> $HOME/$shellrc

if [ -d ~/$shellrcd ]; then
    for file in ~/$shellrcd/*.sh; do
        source \$file
    done
fi
EOF

rm -rf $HOME/.config/nvim
ln -sf $curr_dir/.config/nvim $HOME/.config/nvim
