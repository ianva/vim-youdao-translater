# vim youdao translater

vim youdao translater 是一个利用 [有道词典在线版](http://dict.youdao.com/) 制作的vim插件，可以帮你在 vim 中翻译单词

##安装

###普通安装:  
把 `ydt.vim` 文件拷贝到 `~/.vim/plugin` 目录下，就可以用了。 


### pathogen 安装：
如果装有 pathogen 可以 :

	cd ~/.vim/bundle
	git clone git@github.com:ianva/vim-youdao-translater.git


###  其他
插件依赖于python 的 Requests， 安装 Requests：`sudo pip install requests`。

添加 `~/.vimrc` 文件：


	vnoremap <silent> <C-T> <Esc>:Ydv<CR> 
	nnoremap <silent> <C-T> <Esc>:Ydc<CR> 
	noremap <leader>yd :Yde<CR>


##如何使用

在普通模式下，按 `ctrl+t`， 会翻译当前光标下的单词；

在 `visual` 模式下选中单词，按 `ctrl+t`，会翻译选择的单词；

点击引导键再点y，d，可以在命令行输入要翻译的单词；

译文将会在编辑器底部的命令栏显示。 



##License
Copyright (c) ianva



