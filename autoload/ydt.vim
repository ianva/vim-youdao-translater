function! ydt#VimOutCallback(chan, msg)
    echo a:msg
endfunction

" This function taken from the lh-vim repository
function! ydt#GetVisualSelection()
    try
        let a_save = @a
        normal! gv"ay
        return @a
    finally
        let @a = a_save
    endtry
endfunction

function! ydt#GetAvailablePythonCmd()
    for cmd in ['python', 'python2', 'python3']
        if executable(cmd)
            return cmd
        endif
    endfor

    return ""
endfunction
