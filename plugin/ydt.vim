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
import vim,urllib,re,collections,xml.etree.ElementTree as ET

# -*- coding: utf-8 -*-

WARN_NOT_FIND = " 找不到该单词的释义".decode('utf-8')
ERROR_QUERY = " 有道翻译查询出错!".decode('utf-8')
NETWORK_ERROR = " 无法连接有道服务器!".decode('utf-8')

def split_word(word):
    array = []
    for i in word.split('_'):
        array += i.split('\n')
    word = []
    p = re.compile('[a-z][A-Z]')
    for piece in array:
        lastIndex = 0
        for i in p.finditer(piece):
            word.append(piece[lastIndex:i.start() + 1])
            lastIndex = i.start() + 1
        word.append(piece[lastIndex:])
    return ' '.join(word)

def get_word_info(word):
    word = word.strip()
    word = split_word(word)
    if not word:
        return ''
    try:
        r = urllib.urlopen("http://dict.youdao.com" + "/fsearch?q=" + word.encode('utf-8'))
    except IOError, e:
        return NETWORK_ERROR
    if r.getcode() == 200:
        doc = ET.fromstring(r.read())
        info = collections.defaultdict(list)

        if not len(doc.findall(".//content")):
            return WARN_NOT_FIND

        phrase = doc.find(".//return-phrase").text
        p = re.compile(r"^%s$"%word, re.IGNORECASE)
        if p.match(phrase):
            for el in doc.findall(".//"):
                if el.tag in ('return-phrase','phonetic-symbol'):
                    if el.text:
                        info[el.tag].append(el.text.encode("utf-8"))
                elif el.tag in ('content','value'):
                    if el.text:
                        info[el.tag].append(el.text.encode("utf-8"))

            for k,v in info.items():
                info[k] = ' | '.join(v) if k == "content" else ' '.join(v)

            tpl = ' %(return-phrase)s'
            if info["phonetic-symbol"]:
                tpl = tpl + ' [%(phonetic-symbol)s]'
            tpl = tpl +' %(content)s'

            return tpl % info
        else:
            try:
                r = urllib.urlopen("http://fanyi.youdao.com" + "/translate?i=" + word.encode('utf-8'))
            except IOError, e:
                return NETWORK_ERROR
            p = re.compile(r"\"translateResult\":\[\[{\"src\":\"%s\",\"tgt\":\"(?P<result>.*)\"}\]\]"
                    % word.encode('utf-8'))
            s = p.search(r.read())
            if s:
                return "%s %s" % (word, s.group('result').decode('utf-8'))
            else:
                return ERROR_QUERY
    else:
        return  ERROR_QUERY

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
