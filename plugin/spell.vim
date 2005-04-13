" File: spell.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 1.2
" Last Modified: April 13, 2005
"
" Vim plugin for using the 'spell' Unix utility.  Provides commands to spell
" check the current buffer, or a range of lines in the current buffer, current
" word or a supplied string and to highlight misspelled words.  This plugin
" provides the functionality similar to that provided by the emacs spell.el
" script.
"
" This plugin provides the following commands: 
"
"    1. Spell
"       Spell check lines in the current buffer.  The default behavior is to
"       spell check the entire buffer. You can specify an ex command-line
"       range to spell check only lines in that range. If a word is
"       misspelled, you will be prompted to enter the correct spelling for the
"       word.  If you enter the correct spelling, then you will be prompted
"       for replacing every occurrence of that word in the current buffer.  If
"       you press just enter, then the word will be skipped.  If you press
"       <Esc>, the spell check will be stopped. 
"
"    2. SpellWord 
"       Check the spelling of the current word under the cursor. If the word
"       is misspelled, you will be prompted for the correct spelling.  If you
"       enter the correct spelling, you will be prompted for replacing every
"       occurrence of that word in the current buffer.  If you press just
"       enter, then the word will be skipped. 
"
"    3. SpellString <string> 
"       Check the spelling of the supplied string.  All the misspelled words
"       in the string will be displayed. 
"
"    4. SpellHighlight
"       Highlight all the misspelled words in the current buffer. This command
"       also takes a range of lines.
"
"    5. SpellHighlightClear
"       Clear the highlighting for the misspelled words.
"
" The 'spell' utility only checks the spelling and will not provide the 
" alternatives (correct spelling) for a word.  As this plugin depends on the 
" 'spell' utility, you will not get the correct spelling for a word.  You will 
" only know whether a word is spelled correctly or not.
"

if exists('loaded_spell') || &cp
    finish
endif
let loaded_spell = 1

" Location of the spell utility.  Modify this variable to point to the correct
" location of the spell utility
if !exists('SpellPath')
    let SpellPath = '/usr/bin/spell'
endif

" --------------------- Do not edit after this line ------------------------

" Define the spell error highlighting.
" Use colors only if running GUI Vim or if the terminal supports colors.
" For non-color terminal use reverse colors.
hi clear SpellError
if has('gui_running') || &t_Co > 2
    highlight SpellError term=reverse cterm=bold
    highlight SpellError ctermfg=7 ctermbg=1 guifg=Red guibg=White
else
    highlight SpellError term=reverse cterm=reverse
endif

" F_Spell
" Spell check the selected range of lines (default is the entire buffer)
"     hl_errors - Whether to highlight the errors or not
function! s:F_Spell(hl_errors) range
    let range = a:firstline . ',' . a:lastline

    " Save the contents of the range of lines to a temporary file.
    let tmpfile = tempname()

    exe 'silent ' . range . 'write! >> ' . tmpfile

    " Run 'spell' and get the misspelled words
    let cmd = g:SpellPath . ' ' . tmpfile
    let cmd_output = system(cmd)

    call delete(tmpfile)

    if v:shell_error && cmd_output != ''
        echohl WarningMsg | echomsg cmd_output | echohl None
        return
    endif

    if cmd_output == ''
        echo 'No spelling errors found.'
        return
    endif

    if a:hl_errors == 1
        " Only highlight the errors
        let repl = 'syntax match SpellError /\\<&\\>/'
        let cmd_output = substitute(cmd_output, "[^\n]\\+", repl, 'g')

        exe cmd_output

        return
    endif

    let len = strlen(cmd_output)

    " Process all the misspelled words
    while cmd_output != ''
        " Extract one misspelled word from the spell output
        let one_word = strpart(cmd_output, 0, stridx(cmd_output, "\n"))
        let cmd_output = strpart(cmd_output, stridx(cmd_output, "\n") + 1, len)

        " Get the correct spelling from user
        let prompt = 'Enter the correct spelling for (' . one_word . '): '
        let correct_word = input(prompt, one_word)
        if correct_word == ''
            " User pressed escape or entered empty text
            return 1
        endif

        " If the user selected the same word then skip it, otherwise
        " asks the user for every instance of the misspelled word
        if correct_word != one_word
            exe range . 's/\<' . one_word . '\>/' . correct_word . '/c'
        endif
    endwhile

    echo "\nCompleted spell checking."
endfunction

" F_SpellWord
" Spell check the word under the cursor.
function! s:F_SpellWord()
    let word = expand('<cword>')
    if word == ''
        return
    endif

    " Save the word to a temporary file.
    let tmpfile = tempname()

    exe 'redir! > ' . tmpfile
    silent echo word . "\n"
    redir END

    " Run 'spell' and check whether the word is misspelled
    let cmd = g:SpellPath . ' ' . tmpfile
    let cmd_output = system(cmd)

    call delete(tmpfile)

    if v:shell_error && cmd_output != ''
        echohl WarningMsg | echomsg cmd_output | echohl None
        return
    endif

    if cmd_output == ''
        echo "'" . word . "' spelled correctly."
        return
    endif

    " Get the correct spelling from user
    let prmpt = 'Enter correct spelling for (' . word . '): '
    let correct_word = input(prmpt, word)

    " If the user selected the same word then skip it, otherwise
    " asks the user for every instance of the misspelled word
    if correct_word != word
        " Start from the top of the file
        exe '%s/\<' . word . '\>/' . correct_word . '/c'
    endif
endfunction

" F_SpellString
" Spell check the supplied string
function! s:F_SpellString(str)
    if a:str == ''
        return
    endif

    " Save the string to a temporary file.
    let tmpfile = tempname()

    exe 'redir! > ' . tmpfile
    silent echo a:str . "\n"
    redir END

    " Run 'spell' and check whether the word is misspelled
    let cmd = g:SpellPath . ' ' . tmpfile
    let cmd_output = system(cmd)

    call delete(tmpfile)

    if v:shell_error && cmd_output != ''
        echohl WarningMsg | echomsg cmd_output | echohl None
        return
    endif

    if cmd_output == ''
        echo "'" . a:str . "' is spelled correctly."
        return
    endif

    " Replace all newlines with space
    let cmd_output = substitute(cmd_output, "\n", ' ', 'g')

    echo 'Misspelled words: ' . cmd_output
endfunction

command! -nargs=0 -range=% Spell <line1>,<line2>call s:F_Spell(0)
command! -nargs=0 SpellWord call s:F_SpellWord()
command! -nargs=1 SpellString call s:F_SpellString(<args>)
command! -nargs=0 -range=% SpellHighlight <line1>,<line2>call s:F_Spell(1)
command! -nargs=0 SpellHighlightClear syntax clear SpellError

