#!/bin/bash

system=$(uname)
if [[ $system == "Darwin" ]]; then
	shellrc=".zshrc"
	shellrcd=".zshrc.d"
elif [[ $system == "Linux" ]]; then
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

if [[ $system == "Darwin" ]]; then
    cat <<EOF >> $HOME/$shellrc

autoload -Uz select-word-style
select-word-style bash
EOF
fi

rm -rf $HOME/.config/nvim
ln -sf $curr_dir/.config/nvim $HOME/.config/nvim
