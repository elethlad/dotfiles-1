#!/bin/bash

while true; do
	read -e -p 'sudo apt-get install ' -i "$(tr '\n' ' ' < ~/dotfiles/packages)" install
	case $install in
	'' ) break ;;
	* )
		sudo apt-get install $install
		break ;;
	esac
done

if ! type 'vim' &> /dev/null; then
	echo 'warning: vim not found'
else
	while true; do
		read -e -p 'install vim plugins? (y/n) ' vimplugins
		case $vimplugins in
			[Yy]* )
				ln -vfs ~/dotfiles/.vimrc ~
				mkdir -vp ~/.vim/{bundle,colors,cache,undo,backups,swaps}
				git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
				vim +NeoBundleUpdate +q
				break ;;
			* ) break ;;
		esac
	done
fi

if ! type 'zsh' &> /dev/null; then
	echo 'warning: zsh not found'
else
	while true; do
		read -e -p 'git clone oh-my-zsh and plugins? (y/n) ' zshconf
		case $zshconf in
			[Yy]* )
				ln -vfs ~/dotfiles/.zshrc ~
				git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
				mkdir -vp ~/.oh-my-zsh/custom/plugins
				git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
				break ;;
			* ) break ;;
		esac
	done
fi

if ! type "awesome" &> /dev/null; then
	echo &> /dev/null
else
	while true; do
		read -e -p 'symlink awesome dir? (y/n) ' awesomeconf
		case $awesomeconf in
			[Yy]* )
				ln -svf ~/dotfiles/.config/awesome ~/.config
				break ;;
			*) break ;;
		esac
	done
fi