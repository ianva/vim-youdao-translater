# vim youdao translater(ydt)

ydt 是一个利用 [有道词典在线版](http://dict.youdao.com/) 制作的vim插件，可以翻译 `visual` 模式下选定的单词。

##Installation

1. 把 `ydt.vim` 文件拷贝到 `~/.vim/plugin` 目录下。
2. 添加 `vnoremap <silent> <C-T> <Esc>:Ydt<CR> ` 到 `~/.vimrc` 文件。
3. 该插件依赖于ruby，目前在ruby 1.9.2 上没有问题, 同时依赖一个xml解析库 [REXML](http://raa.ruby-lang.org/project/rexml/) 请下载安装。

##How to use it

在 `visual` 模式下选中单词，按 `ctrl+t`，译文将会在编辑器底部的命令栏显示。 


##License
Copyright (c) ianva


