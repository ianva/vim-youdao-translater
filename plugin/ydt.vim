"Check if py3 is supported
function! s:UsingPython3()
  if has('python3')
    return 1
  endif
  if has('python')
    return 0
  endif
  echo "Error: Required vim compiled with +python"
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

PY3K = sys.version_info >= (3, 0)

try:
    from urllib.parse import urlparse, urlencode
    from urllib.request import urlopen, Request
    from urllib.error import HTTPError
except ImportError:
    from urlparse import urlparse
    from urllib import urlencode
    from urllib2 import urlopen, Request, HTTPError

if PY3K:
    WARN_NOT_FIND = " 找不到该单词的释义"
    ERROR_QUERY = " 有道翻译查询出错!"
    NETWORK_ERROR = " 无法连接有道服务器!"
else:
    WARN_NOT_FIND = " 找不到该单词的释义".decode('utf-8')
    ERROR_QUERY = " 有道翻译查询出错!".decode('utf-8')
    NETWORK_ERROR = " 无法连接有道服务器!".decode('utf-8')

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
        if PY3K:
            url = 'http://dict.youdao.com' + '/fsearch?q=' + urllib.parse.quote(word)
        else:
            url = 'http://dict.youdao.com' + '/fsearch?q=' + urllib.quote(word.encode('utf-8'))
        r = urlopen(url)
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
                if PY3K:
                    info[k] = info[k].decode()

            tpl = ' %(return-phrase)s'
            if info["phonetic-symbol"]:
                tpl = tpl + ' [%(phonetic-symbol)s]'
            tpl = tpl +' %(content)s'

            return tpl % info
        else:
            try:
                if PY3K:
                    url = "http://fanyi.youdao.com" + "/translate?i=" + urllib.parse.quote(word)
                else:
                    url = "http://fanyi.youdao.com" + "/translate?i=" + urllib.quote(word.encode('utf-8'))
                r = urlopen(url)
            except IOError:
                return NETWORK_ERROR

            if PY3K:
                p = re.compile(r"\"translateResult\":\[\[{\"src\":\"%s\",\"tgt\":\"(?P<result>.*)\"}\]\]" % word)
            else:
                p = re.compile(r"\"translateResult\":\[\[{\"src\":\"%s\",\"tgt\":\"(?P<result>.*)\"}\]\]" % word.encode('utf-8'))

            r_result = r.read()
            if PY3K:
                r_result = r_result.decode('utf-8')
            s = p.search(r_result)
            if s:
                if PY3K:
                    return " %s" % s.group('result')
                else:
                    return " %s" % s.group('result').decode('utf-8')
            else:
                return ERROR_QUERY
    else:
        return  ERROR_QUERY

def translate_visual_selection(lines):
    if not PY3K:
        lines = lines.decode('utf-8')
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
