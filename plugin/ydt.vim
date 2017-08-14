"Check if py3 is supported
function! s:UsingPython3()
  if has('python3')
    return 1
  endif
  if has('python')
    return 0
  endif
  echo "Error: Required vim compiled with +python/+python3"
  finish
endfunction

let s:using_python3 = s:UsingPython3()
let s:python_until_eof = s:using_python3 ? "python3 << EOF" : "python << EOF"
let s:python_command = s:using_python3 ? "py3 " : "py "

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

exec s:python_until_eof

# -*- coding: utf-8 -*-
import vim,urllib,re,collections,xml.etree.ElementTree as ET
import sys

try:
    from urllib.parse import urlparse, urlencode
    from urllib.request import urlopen, Request
    from urllib.error import HTTPError
except ImportError:
    from urlparse import urlparse
    from urllib import urlencode
    from urllib2 import urlopen, Request, HTTPError

def str_encode(word):
    if sys.version_info >= (3, 0):
        return word
    else:
        return word.encode('utf-8')

def str_decode(word):
    if sys.version_info >= (3, 0):
        return word
    else:
        return word.decode('utf-8')

def bytes_decode(word):
    if sys.version_info >= (3, 0):
        return word.decode()
    else:
        return word

def url_quote(word):
    if sys.version_info >= (3, 0):
        return urllib.parse.quote(word)
    else:
        return urllib.quote(word.encode('utf-8'))

WARN_NOT_FIND = str_decode(" 找不到该单词的释义")
ERROR_QUERY   = str_decode(" 有道翻译查询出错!")
NETWORK_ERROR = str_decode(" 无法连接有道服务器!")

QUERY_BLACK_LIST = ['.', '|', '^', '$', '\\', '[', ']', '{', '}', '*', '+',
        '?', '(', ')', '&', '=', '\"', '\'', '\t']

def preprocess_word(word):
    word = word.strip()
    for i in QUERY_BLACK_LIST:
        word = word.replace(i, ' ')
    array = word.split('_')
    word = []
    p = re.compile('[a-z][A-Z]')
    for piece in array:
        lastIndex = 0
        for i in p.finditer(piece):
            word.append(piece[lastIndex:i.start() + 1])
            lastIndex = i.start() + 1
        word.append(piece[lastIndex:])
    return ' '.join(word).strip()


def get_word_info(word):
    word = preprocess_word(word)
    if not word:
        return ''
    try:
        r = urlopen('http://dict.youdao.com' + '/fsearch?q=' + url_quote(word))
    except IOError:
        return NETWORK_ERROR
    if r.getcode() == 200:
        doc = ET.fromstring(r.read())

        phrase = doc.find(".//return-phrase").text
        p = re.compile(r"^%s$"%word, re.IGNORECASE)
        if p.match(phrase):
            info = collections.defaultdict(list)

            if not len(doc.findall(".//content")):
                return WARN_NOT_FIND

            for el in doc.findall(".//"):
                if el.tag in ('return-phrase','phonetic-symbol'):
                    if el.text:
                        info[el.tag].append(el.text.encode("utf-8"))
                elif el.tag in ('content','value'):
                    if el.text:
                        info[el.tag].append(el.text.encode("utf-8"))

            for k,v in info.items():
                info[k] = b' | '.join(v) if k == "content" else b' '.join(v)
                info[k] = bytes_decode(info[k])

            tpl = ' %(return-phrase)s'
            if info["phonetic-symbol"]:
                tpl = tpl + ' [%(phonetic-symbol)s]'
            tpl = tpl +' %(content)s'

            return tpl % info
        else:
            try:
                r = urlopen("http://fanyi.youdao.com" + "/translate?i=" + url_quote(word))
            except IOError:
                return NETWORK_ERROR

            p = re.compile(r"\"translateResult\":\[\[{\"src\":\"%s\",\"tgt\":\"(?P<result>.*)\"}\]\]" % str_encode(word))

            r_result = bytes_decode(r.read())
            s = p.search(r_result)
            if s:
                return str_decode(s.group('result'))
            else:
                return ERROR_QUERY
    else:
        return  ERROR_QUERY

def translate_visual_selection(lines):
    lines = str_decode(lines)
    for line in lines.split('\n'):
        info = get_word_info(line)
        vim.command('echo "'+ info +'"')
EOF

function! s:YoudaoVisualTranslate()
    exec s:python_command 'translate_visual_selection(vim.eval("<SID>GetVisualSelection()"))'
endfunction

function! s:YoudaoCursorTranslate()
    exec s:python_command 'translate_visual_selection(vim.eval("<SID>GetCursorWord()"))'
endfunction

function! s:YoudaoEnterTranslate()
    let word = input("Please enter the word: ")
    redraw!
    exec s:python_command 'translate_visual_selection(vim.eval("word"))'
endfunction

command! Ydv call <SID>YoudaoVisualTranslate()
command! Ydc call <SID>YoudaoCursorTranslate()
command! Yde call <SID>YoudaoEnterTranslate()
