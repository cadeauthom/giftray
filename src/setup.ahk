/*
    This file is part of Giftray.
    Copyright 2020 cadeauthom <cadeauthom@gmail.com>

    Giftray is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
#SingleInstance force
#NoTrayIcon

;Gui, Add, Progress, w200 h20 cBlue vMyProgress, 75
;GuiControl,, MyProgress, +20  ; Increase the current position by 20.
;GuiControl,, MyProgress, 50  ; Set the current position to 50.

SplitPath, A_ScriptDir, dir, pathminus,
if ( dir = "src" )
    SetWorkingDir %pathminus%
else
    SetWorkingDir %A_ScriptDir%

;-----------------------------------------------------
if A_Args[1]
    project := A_Args[1]
else
    exit -1
installdir := a_ProgramFiles "\" project
builddir := "build"
fileout := builddir "\setup_" project ".ahk"
fileun := builddir "\uninstall_" project ".ahk"

;-----------------------------------------------------
alldir := installdir
alldir := alldir "," installdir "\icons"
menu := A_StartMenuCommon "\" project
alldir := alldir "," menu
allfiles := project ".exe"
allfiles := allfiles ",README.md"
allfiles := allfiles ",uninstall_" project ".exe"
keepfiles := project ".conf"
keepfiles := keepfiles ",key.csv"
keepdir := installdir "\" project ".conf.d"
Loop Files, %builddir%\icons\*
{
    allfiles:= allfiles ",icons\" A_LoopFileName
}

;-----------------------------------------------------
FileDelete % fileout
FileDelete % fileun

;---- admin
text2 := "#SingleInstance force`r"
text2 := text2 "#NoTrayIcon`r"
text2 := text2 "if not (A_IsAdmin)`r{`r"
text2 := text2 "`ttry Run *RunAs ""`%A_ScriptFullPath`%""`r"
text2 := text2 "`treturn`r}`r`r"
text := text2

;---- msgbox
text := text "MsgBox, 0x21, " project ", Install " project " tool ?`r"
text := text "IfMsgBox, OK`r`tinstall()`r"
text2 := text2 "MsgBox, 0x23, " project ", You are trying to remove " project " tool. Do you want to keep configuration files ?`r"
text2 := text2 "IfMsgBox, YES`r`t`tremove(1)`r"
text2 := text2 "IfMsgBox, NO`r`t`tremove(0)`r"

;---- function
text := text "`rinstall()`r{`r"
text2 := text2 "`rremove(keep)`r{`r"

;---- dir (install)
for i,dir in StrSplit(alldir , ",")
    text := text "`tFileCreateDir, " dir "`r"
for i,dir in StrSplit(keepdir , ",")
    text := text "`tFileCreateDir, " dir "`r"

;---- files & shortcut
for i,file in StrSplit(allfiles , ",")
{
    text := text "`tFileInstall, " file ",  " installdir "\" file " , 1`r"
    text2 := text2 "`tFileDelete " file "`r"
    if ( RegExMatch(file, "(.*)\.exe$",lnk) )
    {
        text := text "`tFileCreateShortcut  , " installdir "\" file " , " menu "\" lnk1 ".lnk , " installdir "\,,,`r"
        text2 := text2 "`tFileDelete " menu "\" lnk1 ".lnk`r"
    }
}

;---- conf files
text2 := text2 "`tif (not keep)`r`t{`r"
for i,file in StrSplit(keepfiles , ",")
{
    text := text "`tFileInstall, " file ",  " installdir "\" file " , 0`r"
    text2 := text2 "`t`tFileDelete " file "`r"
}
text2 := text2 "`t}`r"

;---- startup shortcut
text := text "`tFileCreateShortcut  , " installdir "\" project ".exe ," A_StartupCommon "\" project ".lnk , " installdir "\,,Menu and HotKeys for simpler usage.,"
text2 := text2 "`tFileDelete " A_StartupCommon "\" project ".lnk`r"

;---- dir (remove)
a:=StrSplit(keepdir , ",")
l:=a.Length()
text2 := text2 "`tif (not keep)`r`t{`r"
loop % l
{
    dir := a[l - A_Index + 1]
    text2 := text2 "`tFileRemoveDir, " dir ",0`r"
}
text2 := text2 "`t}`r"
a:=StrSplit(alldir , ",")
l:=a.Length()
loop % l
{
    dir := a[l - A_Index + 1]
    text2 := text2 "`tFileRemoveDir, " dir ",0`r"
}

;---- end
text := text "`r}"
text2 := text2 "}"

FileAppend, %text%, %fileout%
FileAppend, %text2%, %fileun%

return
