;-------------------------------------------------------------------------------
; Copyright (c) 2015 Artur Eganyan
; 
; This software is provided "AS IS", WITHOUT ANY WARRANTY, express or implied.
;-------------------------------------------------------------------------------

#SingleInstance force
Process Priority, , High
SendMode Input


;-------------------------------------------------------------------------------
; Configuration
;-------------------------------------------------------------------------------

; Browser executables for which some hotkeys will work (see "Browser" section). 
;
; Note: Not only browsers but any executable with one of these names will 
; receive the hotkeys. You can add a criteria like a window class ("ahk_class 
; <class>" after the exe name) to make the detection more precise.

GroupAdd Browser, ahk_exe chrome.exe 
GroupAdd Browser, ahk_exe firefox.exe
GroupAdd Browser, ahk_exe opera.exe


; Programs and sites

NOTEPAD = notepad.exe

CONSOLE = cmd

SEARCH = https://www.google.com
SEARCH_QUERY = %SEARCH%/search?q=

MAPS = https://maps.yandex.com
MAPS_QUERY = %MAPS%/?text=

; MAPS = https://www.google.com/maps
; MAPS_QUERY = %MAPS%/search/

WIKIPEDIA = http://en.wikipedia.org
WIKIPEDIA_QUERY = %WIKIPEDIA%/w/index.php?search=

MAIL = https://mail.google.com

return


;-------------------------------------------------------------------------------
; Windows management
;-------------------------------------------------------------------------------

#if

; Alt + Q closes active window
!Q::WinClose A

; Alt + Down/Up minimizes/maximizes active window
!Down::WinMinimize A
!Up::WinMaximize A

; Win + C centers active window
#C::centerWindow("A")

; Ctrl + Shift + N opens notepad
^+N::Run % NOTEPAD

; Ctrl + Shift + K opens windows console
^+K::Run % CONSOLE


;-------------------------------------------------------------------------------
; Browser
;-------------------------------------------------------------------------------

#if (WinActive("ahk_group Browser"))

; Ctrl + Up opens new tab
^Up::SendInput ^{vk54sc014}

; Ctrl + Down closes new tab
^Down::SendInput ^{F4}

; Ctrl + Left/Right and Ctrl + Wheel switch tabs
^Right::SendInput ^{Tab}
^Left::SendInput ^+{Tab}

^WheelDown::SendInput ^{Tab}
^WheelUp::SendInput ^+{Tab}

; Ctrl + Q closes current tab
^Q::SendInput ^{vk57sc011} ; Ctrl + W, W = 57 011


;-------------------------------------------------------------------------------
; Useful sites
;-------------------------------------------------------------------------------

#if

; Ctrl + Shift + H opens default search page
^+H::Run % SEARCH

; Ctrl + Shift + G searches selected text on web
^+G::Run % SEARCH_QUERY . selectedText_urlEncoded()

; Ctrl + Shift + W searches selected text on wikipedia
^+W::Run % WIKIPEDIA_QUERY . selectedText_urlEncoded()

; Ctrl + Shift + Y searches selected text on maps
^+Y::Run % MAPS_QUERY . selectedText_urlEncoded()

; Ctrl + Shift + M opens mail
^+M::Run % MAIL


;-------------------------------------------------------------------------------
; Utils
;-------------------------------------------------------------------------------

; Returns text selected in active window
selectedText()
{
    ClipboardOld := ClipboardAll
    Clipboard := 
    Send ^{vk43sc02E}  ; Ctrl + C, C = 43 02E
    ClipWait 0.1       ; If Clipboard is still empty, waits 0.1 second
    if (ErrorLevel)
        return
    result := Clipboard
    Clipboard := ClipboardOld
    return result
}

; The same as selectedText(), but the result is url encoded
selectedText_urlEncoded()
{
    return urlEncoded(selectedText())
}

; Centers the window pointed by winTitle
centerWindow( winTitle )
{
    SysGet desktop, Monitor
    WinGetPos x, y, w, h, %winTitle% 
    x := (desktopRight - w) / 2
    y := (desktopBottom - h) / 2
    WinMove %winTitle%, , %x%, %y%
}

; Converts the text to utf-8, then converts each byte of utf-8 to the 
; hexademical string "%XX" and returns the result sequence. The text 
; should be wide character.
hexString( ByRef text )
{
    ; Convert text to utf-8
    length := StrPut(text, "utf-8") 
    VarSetCapacity(utf8, length)
    StrPut(text, &utf8, "utf-8")
    
    ; Convert each byte of utf-8 to "%XX"
    VarSetCapacity(hex, length * 3 + 16, 0)
    byte := &utf8
    i := 0
    
    while (*byte) {
        DllCall("wsprintf", "Ptr", &hex + i, "Str", "%%%02X", "Int", *(byte ++), "Cdecl")
        i += 6  ; "%XX" occupies 6 bytes
    }
    
    ; Update internal length of the string to the length of its content.
    ; This is required at least for AHK v1.1.11.01.
    VarSetCapacity(hex, -1)
    
    return hex
}

; Returns url encoded (percent-encoded) text. Note: if the text contains 
; a protocol (e.g. "http://"), it will also be encoded, so be careful.
urlEncoded( text )
{
    ; Replace all % with %25
    StringReplace text, text, `%, `%25, A

    ; Encode anything which is not a word character, dot, ~ or %  
    shouldBeEncoded := "i)[^\w\.~%]"
    while (RegExMatch(text, shouldBeEncoded, found)) {
        StringReplace text, text, %found%, % hexString(found), A
    }
    
    return text
}
