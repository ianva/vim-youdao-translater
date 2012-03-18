"
if !has("ruby")
  finish
end
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

ruby << EOF
require 'net/http'
require 'rexml/document'

include Net
include REXML

def get_wordInfo word
    headers, body = HTTP.new("dict.youdao.com").get "/fsearch?q=#{word}"
    info = {}
    if headers.code == '200'
        doc = Document.new body
        XPath.each(doc,'//*') { |node| 
            case node.name
            when "return-phrase", "phonetic-symbol"	
                info[node.name] = node.text.to_s
            when "content", "value"
                unless info[node.name].class.to_s == "Array"
                    info[node.name]=[]
                end
                info[node.name] << node.text
            end
        }
    else
	    info = nil
    end
    info
end

def translate_visual_selection 
    word = VIM::evaluate "<SID>GetVisualSelection()"
    info = get_wordInfo word
    if info
        print " #{word}: [#{info["phonetic-symbol"]}] #{info["content"].join(" | ")}" 
    else
        print "Error while querying Youdao"
    end
end 

EOF

function! s:YoudaoTranslate()
    ruby translate_visual_selection
endfunction

command Ydt :call <SID>YoudaoTranslate()
