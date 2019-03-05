# vim youdao translater

vim youdao translater 是一个利用 [有道词典在线版](http://dict.youdao.com/) 制作的vim插件，可以帮你在 vim 中翻译单词或语句

## 安装

### 普通安装:
把所有文件拷贝到 `~/.vim/` 目录下，就可以用了。


### pathogen 安装：
如果装有 pathogen 可以 :

	cd ~/.vim/bundle
	git clone git@github.com:ianva/vim-youdao-translater.git


###  其他
添加 `~/.vimrc` 文件：

```vim
vnoremap <silent> <C-T> :<C-u>Ydv<CR>
nnoremap <silent> <C-T> :<C-u>Ydc<CR>
noremap <leader>yd :<C-u>Yde<CR>
```

## 如何使用

在普通模式下，按 `ctrl+t`， 会翻译当前光标下的单词；

在 `visual` 模式下选中单词或语句，按 `ctrl+t`，会翻译选择的单词或语句；

点击引导键再点y，d，可以在命令行输入要翻译的单词或语句；

译文将会在编辑器底部的命令栏显示。



## License

The MIT License (MIT)

Copyright (c) ianva



