# -*- coding: utf-8 -*-
import urllib, re, collections, xml.etree.ElementTree as ET
import sys, json
import io, platform

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


WARN_NOT_FIND = " 找不到该单词的释义"
ERROR_QUERY = " 有道翻译查询出错!"
NETWORK_ERROR = " 无法连接有道服务器!"

QUERY_BLACK_LIST = ['.', '|', '^', '$', '\\', '[', ']', '{', '}', '*', '+', '?', '(', ')', '&', '=', '\"', '\'', '\t']


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
        p = re.compile(r"^%s$" % word, re.IGNORECASE)
        if p.match(phrase):
            info = collections.defaultdict(list)

            if not len(doc.findall(".//content")):
                return WARN_NOT_FIND

            for el in doc.findall(".//"):
                if el.tag in ('return-phrase', 'phonetic-symbol'):
                    if el.text:
                        info[el.tag].append(el.text.encode("utf-8"))
                elif el.tag in ('content', 'value'):
                    if el.text:
                        info[el.tag].append(el.text.encode("utf-8"))

            for k, v in info.items():
                info[k] = b' | '.join(v) if k == "content" else b' '.join(v)
                info[k] = bytes_decode(info[k])

            tpl = ' %(return-phrase)s'
            if info["phonetic-symbol"]:
                tpl = tpl + ' [%(phonetic-symbol)s]'
            tpl = tpl + ' %(content)s'

            return tpl % info
        else:
            try:
                r = urlopen("http://fanyi.youdao.com" + "/translate?i=" + url_quote(word), timeout=5)
            except IOError:
                return NETWORK_ERROR

            p = re.compile(r"global.translatedJson = (?P<result>.*);")

            r_result = bytes_decode(r.read())
            s = p.search(r_result)
            if s:
                r_result = json.loads(s.group('result'))
                if r_result is None:
                    return str_decode(s.group('result'))

                error_code = r_result.get("errorCode")
                if error_code is None or error_code != 0:
                    return str_decode(s.group('result'))

                translate_result = r_result.get("translateResult")
                if translate_result is None:
                    return str_decode(s.group('result'))

                translate_result_tgt = ''
                for i in translate_result:
                    translate_result_tgt = translate_result_tgt + i[0].get("tgt") + "\n"

                return translate_result_tgt
            else:
                return ERROR_QUERY
    else:
        return ERROR_QUERY


if __name__ == "__main__":
    if(platform.system()=='Windows'):
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer,encoding='utf8')
    argv = sys.argv
    info = get_word_info(str_decode("".join(argv[1:])))
    sys.stdout.write(info)
