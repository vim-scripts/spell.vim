" File: spell.vim
" Author: Yegappan Lakshmanan
" Version: 1.0
" Last Modified: February 22 2002
"
" Vim plugin for using the 'spell' Unix utility.  Provides commands to spell
" check the current buffer, visually selected lines, current word or a supplied
" string.  This plugin provides the functionality similar to that provided by 
" the emacs spell.el script. 
"
" This plugin provides the following commands: 
"
"    1. SpellBuffer 
"       Spell check the current buffer.  If a word is misspelled, you will be 
"       prompted to enter the correct spelling for the word.  If you enter the 
"       correct spelling, then you will be prompted for replacing every 
"       occurance of that word in the current buffer.  If you press just 
"       enter, then the word will be skipped.  If you press <Esc>, the spell
"       check will be stopped. 
"
"    2. SpellRegion 
"       Spell check the selected visual lines.  Visually select the lines you 
"       want to spell check and call this command.  Note that this command 
"       will only work on visually selected lines, it will not work on visually 
"       selected columns. 
"
"    3. SpellWord 
"       Check the spelling of the current word under the cursor. If the word 
"       is misspelled, you will be prompted for the correct spelling.  If 
"       you enter the correct spelling, you will be prompted for replacing 
"       every occurance of that word in the current buffer.  If you press 
"       just enter, then the word will be skipped. 
"
"    4. SpellString <string> 
"       Check the spelling of the supplied string.  All the misspelled words
"       in the string will be displayed. 
"
" The 'spell' utility only checks the spelling and will not provide the 
" alternatives (correct spelling) for a word.  As this plugin depends on the 
" 'spell' utility, you will not get the correct spelling for a word.  You will 
" only know whether a word is spelled correctly or not.
"

if exists("loaded_spell")
    finish
endif
let loaded_spell = 1

" Location of the spell utility.  Modify this variable to point to the correct
" location of the spell utility
"let s:SpellPath = 'd:\tools\spell.exe'
let s:SpellPath = '/usr/bin/spell'

" --------------------- Do not edit after this line ------------------------

if !executable(s:SpellPath)
    let msg = "Error: [spell.vim] Spell doesn't exist at " . s:SpellPath
    echohl WarningMsg | echon msg | echohl None
    finish
endif

" Spell check a selected visual region
function! s:F_SpellRegion(start_line, end_line, desc)
    let range = a:start_line . "," . a:end_line

    " Save the contents of the range of lines to a temporary file.
    let tmpfile = tempname()
    execute "silent " . range . "write !cat > " . tmpfile

    " Run 'spell' and get the mispelled words
    let cmd = "cat " . tmpfile . " | " . s:SpellPath
    let cmd_output = system(cmd)

    call delete(tmpfile)

    if v:shell_error && cmd_output != ""
        echohl WarningMsg | echon cmd_output | echohl None
        return
    endif

    if cmd_output == ""
        echo "No spelling errors in the " . a:desc
        return
    endif

    " Process all the mispelled words
    while cmd_output != ""
        " Extract one mispelled word from the spell output
        let one_word = substitute(cmd_output, "\\([^\n]*\\).*", "\\1", "")
        let cmd_output = substitute(cmd_output, "[^\n]*\n", "", "")

        " Get the correct spelling from user
        let prmpt = "Enter correct spelling for (" . one_word . "): "
        let correct_word = input(prmpt, one_word)
        if correct_word == ""
            " User pressed escape or entered empty text
            return 1
        endif

        " If the user selected the same word then skip it, otherwise
        " asks the user for every instance of the mispelled word
        if correct_word != one_word
            exe range . "s/" . one_word . "/" . correct_word . "/c"
        endif
    endwhile

    echo "Completed spell checking the " . a:desc
endfunction

" Spell check the current word or the supplied word
function! s:F_SpellWord()
    let word = expand("<cword>")
    if word == ""
        return
    endif

    " Run 'spell' and check the spelling
    let cmd = "echo " . word . " | " . s:SpellPath
    let cmd_output = system(cmd)

    if v:shell_error && cmd_output != ""
        echohl WarningMsg | echon cmd_output | echohl None
        return
    endif

    if cmd_output == ""
        echo "'" . word . "' spelled correctly"
        return
    endif

    " Get the correct spelling from user
    let prmpt = "Enter correct spelling for (" . word . "): "
    let correct_word = input(prmpt, word)

    " If the user selected the same word then skip it, otherwise
    " asks the user for every instance of the mispelled word
    if correct_word != word
        " Start from the top of the file
        exe "%s/" . word . "/" . correct_word . "/c"
    endif
endfunction

" Spell check the supplied string
function! s:F_SpellString(str)
    if a:str == ""
        return
    endif

    " Run 'spell' and check the spelling
    let cmd = "echo " . a:str . " | " . s:SpellPath
    let cmd_output = system(cmd)

    if v:shell_error && cmd_output != ""
        echohl WarningMsg | echon cmd_output | echohl None
        return
    endif

    if cmd_output == ""
        echo "'" . a:str . "' is spelled correctly"
        return
    endif

    " Replace all newlines with space
    let cmd_output = substitute(cmd_output, "\n", " ", "g")

    echo "Misspelled words: " . cmd_output
endfunction

command! -nargs=0 SpellBuffer call <SID>F_SpellRegion(1, '$', "current buffer")
command! -range -nargs=0 SpellRegion call <SID>F_SpellRegion(<line1>, <line2>,
                                                    \"visually selected region")
command! -nargs=0 SpellWord call <SID>F_SpellWord()
command! -nargs=+ SpellString call <SID>F_SpellString(<q-args>)

