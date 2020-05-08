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
;variables
global global_var :=    {name       :   A_ScriptName    ;name of the tool
                        ,avail:[]       ;installed action
                        ,avail      :   []              ;installed action
                        ,err        :   {}              ;in error action
                        ,install    :   []              ;action tray order
                        ,real       :   []              ;configured action
                        ,nb_install :   0               ;nb of configured action (positive install value)
                        ,nb_default :   0               ;nb of default action (negative install value)
                        ,conf       :   ""              ;configuration file in personnal foler
                        ,admin_conf :   ""              ;configuration file in installation folder
                        ,use_admin  :   0               ;use admin conf because no user conf is set
                        ,doc        :   ""              ;readme file
                        ,icos       :   []              ;tray icons
                        ,icoPath    :   ""              ;icons path
                        ,default_ico:   "default_default"
                        ,empty_ico  :   "default_empty"
                        ;information about build for "about"
                        ,buildinfo  :   {branch :   ""
                                        ,commit :   ""
                                        ,tag    :   ""
                                        ,date   :   A_YYYY A_MM A_DD A_Hour A_Min A_Sec
                                        ,modif  :   -1}
                        ;key modifier for "generator"
                        ,modifier   :   {"Alt"  :   "!"
                                        ,"Win"  :   "#"
                                        ,"Shift":   "+"
                                        ,"Ctrl" :   "^"}}
;tools
main_msgbox(m,tmp){
    a := m "/"
    for i,n in tmp
        if n = "arg"
            a := a "`rarg :" i " : " n
        else
            a := a "`r" i " : " n
    msgbox % a
}
;helper
main_validate_hhk(input_hhk)
{
    a_hhk := StrSplit(input_hhk,"+"," ")
    if (a_hhk.MaxIndex() < 2)
        return
    hhk := ""
    Loop , % a_hhk.MaxIndex() - 1
    {
        key := RegExReplace(key, "^(.?)[mM]aj$", "$1Shift")
        key := RegExReplace(key, "^(.?)[Ww]indows$", "$1Win")
        if a_hhk[A_Index] = "Win"
            key := "Win"
        else
            key := GetKeyName(a_hhk[A_Index])
        if ( ! key ){
            ;msgbox % "Issue while checkink caracter: " a_hhk[A_Index]
            return
        }
        key := RegExReplace(key, "^(.?)Control$", "$1Ctrl")
        if ( ! global_var.modifier[key] )
            return
        hhk := hhk key " + "
    }
    key := RegExReplace(a_hhk[a_hhk.MaxIndex()],"Â","")
    key := GetKeyName(key)
    if ( ! key ){
        ;msgbox % "Issue while checkink caracter: " a_hhk[A_Index]
        return
    }
    if (key.length() > 1)
    {
        Switch SubStr(key, 1 , 1)
        {
        Case "L":
            s := SubStr(key, 2)
        Case "R":
            s := SubStr(key, 2)
        Default:
            s := key
        }
        if global_var.modifier[s]
            return
        key := RegExReplace(key, "^BS$", "BackSpace")
    }
    return hhk key
}
main_string_to_key(hhk)
{
    a_hhk := StrSplit(hhk,"+"," ")
    if (a_hhk.MaxIndex() < 2)
        return
    ahk := ""
    Loop , % a_hhk.MaxIndex() - 1
    {
        Switch SubStr(a_hhk[A_Index], 1 , 1)
        {
        Case "L":
            ahk := ahk "<"
            s := SubStr(a_hhk[A_Index], 2)
        Case "R":
            ahk := ahk "<"
            s := SubStr(a_hhk[A_Index], 2)
        Default:
            s := a_hhk[A_Index]
        }
        mod := global_var.modifier[s]
        if mod
            ahk := ahk mod
        else
            return
    }
    return ahk a_hhk[a_hhk.MaxIndex()]
}
main_ExecScript(Script, Wait:=true)
{
    shell := ComObjCreate("WScript.Shell")
    s := "cmd /c title " script " &  " script
    ;s :=  script
    exec := shell.Exec(s)
    if Wait
        return exec.StdOut.ReadAll()
}
main_GetPath(app)
{
    if not app
        return
    IfExist, %app%
        return app
    path := main_ExecScript("where " app)
    if path
        Loop, parse, path, `n, `r
            {
                path := A_LoopField
                break
            }
    else {
        SplitPath, app, , , , no_ext
        app := no_ext
    }
    if (path = )
        RegRead, path, % HKEY_LOCAL_MACHINESOFTWAREMicrosoftWindowsCurrentVersionApp Paths app
    if (path = )
        RegRead, path, % HKEY_LOCAL_MACHINESOFTWAREMicrosoftWindowsCurrentVersionApp Paths app .exe
    if (path = )
        RegRead, path, % HKEY_CLASSES_ROOTApplications app shellopencommand
    if (path = )
        RegRead, path, % HKEY_CLASSES_ROOTApplications app .exeshellopencommand
    return path
}
main_GetCurrentPath(hwnd="") {
    WinGet, process, processName, % "ahk_id" hwnd := hwnd? hwnd:WinExist("A")
    ToReturn := ""
    if (process = "explorer.exe")
        WinGetClass class, ahk_id %hwnd%
        if (class = "WorkerW") {
            ; Bureau
        } else if (class ~= "(Cabinet|Explore)WClass") {
            for window in ComObjCreate("Shell.Application").Windows
                if (window.hwnd==hwnd)
                    ToReturn := window.Document.Folder.Self.path
                ToReturn := Trim(ToReturn,"`n")
        }
    return ToReturn
}
main_createMenu(arg,pos:=0)
{
    if arg["function"]
        function := arg.Delete("function")
    else
        return
    icon := global_var.icoPath function ".ico"
    IfNotExist % icon
        icon := global_var.default_ico

    if arg["name"]
        name := arg.Delete("name")
    else
        return
    print := SubStr(name, 1, 32)

    if arg["hhk"] {
        hhk := arg.Delete("hhk")
        hhk := main_validate_hhk(hhk)
    } else
        hhk := ""

    position:=0
    if pos is integer
        position:=pos

    visible := 0
    if arg["not_in_menu"]
        arg.Delete("not_in_menu")
    else
        visible := 1

    if arg["quick"]
        quick := arg.Delete("quick")
    else
        quick := 0

    if arg["error"]
        error := arg.Delete("error")
    else
        error := ""

    global_var.avail[function]:={ function:function
                                    ,ico:icon
                                    ,pos:position
                                    ,print:print
                                    ,hhk:hhk
                                    ,menu:visible
                                    ,nb:0
                                    ,arg:arg
                                    ,error:error
                                    ,quick:quick}


    if position < 0
    {
        global_var.install[position] := function
        global_var.nb_default++
    }
    return
}
;major functions
main_initialisation()
{
    main_setdefault()
    main_init_plugin()
}
main_setdefault()
{
    SplitPath, A_ScriptFullPath, , , , name_no_ext
    SplitPath, A_ScriptDir, , pathminus,
    name := RegExReplace(name_no_ext, "[-_]" , " ")
    StringLower, name, name , T
    global_var.name := name
    global_var.admin_conf := A_ScriptDir "\" name_no_ext ".conf"
    if ( not FileExist(global_var.admin_conf) ) {
        global_var.conf := pathminus "\conf\" name_no_ext ".conf"
        global_var.admin_conf := pathminus "\conf\" name_no_ext ".conf_FAKEPATH"
    } else {
        dir_conf := A_MyDocuments "\" name_no_ext
        if ( not InStr(FileExist(dir_conf), "D"))
            FileCreateDir, % dir_conf
        global_var.conf := dir_conf "\" name_no_ext ".conf"
        if ( InStr(FileExist(dir_conf), "D"))
            if ( not FileExist(global_var.conf) )
                FileAppend , , % global_var.conf,
    }
    global_var.doc := A_ScriptDir "\README.md"
    if ( not FileExist(global_var.doc) )
        global_var.doc := pathminus "\README.md"
    global_var.icoPath := A_ScriptDir "\icons\"
    if ( not InStr( FileExist(global_var.icoPath), "D") )
        global_var.icoPath := pathminus "\icons\"
    if ( not InStr( FileExist(global_var.icoPath), "D") )
        global_var.icoPath := pathminus "\build\icons\"
    global_var.default_ico := global_var.icoPath global_var.default_ico ".ico"
    IfNotExist % global_var.default_ico
        global_var.default_ico := "294"
    global_var.empty_ico := global_var.icoPath global_var.empty_ico ".ico"
    IfNotExist % global_var.empty_ico
        global_var.empty_ico := "222"
    i := 0
    while true {
        file := global_var.icoPath name_no_ext "-" i ".ico"
        if FileExist(file)
        {
            global_var.icos.push(file)
            i++
        }
        else
        {
            break
        }
    }
    if (global_var.icos.MaxIndex() > 0)
        Menu, Tray, Icon, % global_var.icos[1] , 1
}
main_init_plugin(key:="all")
{
    Switch key
    {
    case "all":
        for i,k in ["default","wsl","virtualBox","windows","android"]
            main_init_plugin(k)
    case "default":
        default_init()
    case "wsl":
        wsl_init()
    case "virtualBox":
        virtualBox_init()
    case "windows":
        windows_init()
    case "android":
        android_init()
    }
}