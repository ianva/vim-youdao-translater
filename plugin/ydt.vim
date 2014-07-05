if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

" This function taken from the lh-vim repository
function! s:GetVisualSelection()
    try
        let a_save = @a
        normal! gv"ay
        return @a
    finally
        let @a = a_save
    endtry
endfunction

function! s:GetCursorWord()
    return expand("<cword>")
endfunction


python << EOF
import vim,requests,collections,xml.etree.ElementTree as ET

# -*- coding: utf-8 -*-

WARN_NOT_FIND = " 找不到该单词的释义"
ERROR_QUERY = " 有道翻译查询出错!"

def get_word_info(word):
    if not word:
        return ''
    r = requests.get("http://dict.youdao.com" + "/fsearch?q=" + word)
    if r.status_code == 200:

        doc = ET.fromstring(r.content)
        info = collections.defaultdict(list)


        if not len(doc.findall(".//content")):
            return WARN_NOT_FIND.decode('utf-8')

        for el in doc.findall(".//"):
            if el.tag in ('return-phrase','phonetic-symbol'):
                if el.text:
                    info[el.tag].append(el.text.encode("utf-8"))
            elif el.tag in ('content','value'):
                info[el.tag].append(el.text.encode("utf-8"))

        for k,v in info.items():
            info[k] = ' | '.join(v) if k == "content" else ' '.join(v)

        tpl = ' %(return-phrase)s'
        if info["phonetic-symbol"]:
            tpl = tpl + ' [%(phonetic-symbol)s]'
        tpl = tpl +' %(content)s' 

        return tpl % info

    else:
        return  ERROR_QUERY.decode('utf-8')

def translate_visual_selection(word):

    word = word.decode('utf-8')
    info = get_word_info( word )
    vim.command('echo "'+ info +'"')

EOF

function! s:YoudaoVisualTranslate()
    python translate_visual_selection(vim.eval("<SID>GetVisualSelection()"))
endfunction

function! s:YoudaoCursorTranslate()
    python translate_visual_selection(vim.eval("<SID>GetCursorWord()"))
endfunction

function! s:YoudaoEnterTranslate()
    let word = input("Please enter the word: ")
    exe "norm! \<Esc><CR>"
    python translate_visual_selection(vim.eval("word"))
endfunction

command! Ydv :call <SID>YoudaoVisualTranslate()
command! Ydc :call <SID>YoudaoCursorTranslate()
command! Yde :call <SID>YoudaoEnterTranslate()


