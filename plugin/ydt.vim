" Check whether python is installed
let s:python_cmd = "python"
if !executable(s:python_cmd)
    let s:python_cmd = "python3"
endif
if !executable(s:python_cmd)
    echoerr "Error: python package need to be installed!"
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

let s:translator_file = expand('<sfile>:p:h') . "/../youdao.py"
let s:translator = {'stdout_buffered': v:true, 'stderr_buffered': v:true}

function! s:translator.on_stdout(jobid, data, event)
    if !empty(a:data) | echo join(a:data) | endif
endfunction
let s:translator.on_stderr = function(s:translator.on_stdout)

function! s:translator.start(lines)
    return jobstart(printf("%s %s %s", s:python_cmd, s:translator_file, a:lines), self)
endfunction

function! s:YoudaoVisualTranslate()
    call s:translator.start(<SID>GetVisualSelection())
endfunction

function! s:YoudaoCursorTranslate()
    call s:translator.start(<SID>GetCursorWord())
endfunction

function! s:YoudaoEnterTranslate()
    let word = input("Please enter the word: ")
    redraw!
    call s:translator.start(word)
endfunction

command! Ydv call <SID>YoudaoVisualTranslate()
command! Ydc call <SID>YoudaoCursorTranslate()
command! Yde call <SID>YoudaoEnterTranslate()
