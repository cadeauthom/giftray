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

;Gui, Add, Progress, w200 h20 cBlue vprogress, 75
;GuiControl,, progress, +20  ; Increase the current position by 20.
;GuiControl,, progress, 50  ; Set the current position to 50.

if A_Args[1]
    project := A_Args[1]
else
    exit -1

if A_Args[2]
    fileout := A_Args[2]
else
    fileout := "build\lib\setup_built.ahk"

fileout := RegExReplace(fileout, "/" , "\")

SplitPath, fileout, , pathminus,
SplitPath, pathminus, , builddir,
installdir := A_Temp "\" project

SplitPath, A_ScriptDir, dir, pathminus,
if ( dir = "src" )
    SetWorkingDir %pathminus%
else
    SetWorkingDir %A_ScriptDir%

;-----------------------------------------------------
var:={}
var.exe := ""
var.menu_dir := ""
var.menu_files := []
var.install_dir := []
var.install_files := []
var.start_files := []
var.conf_dir := []
var.conf_files := []

var.exe := project ".exe"

var.menu_dir := A_StartMenuCommon "\" project

var.install_dir.push(installdir)
var.install_dir.push(installdir "\icons")

var.install_files.push("README.md")


Loop Files, %builddir%\icons\*, D
{
    color := A_LoopFileName
    var.install_dir.push(installdir "\icons\" color)
    Loop Files, %builddir%\icons\%color%\*
        var.install_files.push("icons\" color "\" A_LoopFileName)
}

var.start_files.push(var.exe)
var.start_files.push("setup_" var.exe)

var.conf_dir.push(installdir "\" project ".conf.d")
var.conf_files.push(project ".conf")
Loop Files, %builddir%\%project%.conf.d\*
    var.install_files.push(project ".conf.d" A_LoopFileName)
var.conf_files.push("key.csv")

tab:="`t"

fct:=[]
fct.push("setup_built_install(){")
for i,d in var.install_dir
    fct.push(tab "FileCreateDir, " d)
for i,d in var.conf_dir
    fct.push(tab "FileCreateDir, " d)
for i,file in var.install_files
    fct.push(tab "FileInstall, " file ",  " installdir "\" file " , 1")
for i,file in var.conf_files
    fct.push(tab "FileInstall, " file ",  " installdir "\" file " , 1")
fct.push(tab "return """ var.install_dir[1] """")
fct.push("}")

fct.push("")

fct.push("setup_built_shortcut(dir, boot, menu){")
fct.push(tab "if boot {")
fct.push(tab tab "FileCreateShortcut  , %dir%\" var.exe ", " A_StartupCommon "\" project ".lnk , %dir%, , Menu and HotKeys for simpler usage.,")
fct.push(tab "}")
fct.push(tab "if menu {")
for i,file in var.start_files
    if ( RegExMatch(file, "(.*)\.exe$",lnk) )
        fct.push(tab tab "FileCreateShortcut  , %dir%\" file " , " var.menu_dir "\" lnk1 ".lnk , %dir%,,,")
fct.push(tab "}")
fct.push(tab "return """ var.exe """")
fct.push("}")

fct.push("")

fct.push("setup_built_save_conf(dir){")
fct.push(tab "FileRemoveDir, " var.install_dir[1] ", 1")
fct.push(tab "FileCreateDir, " var.install_dir[1])
for i,d in var.conf_dir
    fct.push(tab "FileCopyDir, %dir%/" d ", " var.install_dir[1] "/" d)
for i,file in var.conf_files
    fct.push(tab "FileCopy, %dir%/" file ", " var.install_dir[1] "/")
fct.push(tab "return """ var.install_dir[1] """")
fct.push("}")

fct.push("")

fct.push("setup_built_rm_start(){")
fct.push(tab "FileDelete " A_StartupCommon "\" project ".lnk")
fct.push(tab "return")
fct.push("}")

line := ""
for a,l in fct
    line := line l "`r`n"


FileDelete % fileout
FileAppend, %line%, %fileout%

return
