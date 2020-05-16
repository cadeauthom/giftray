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
default_init()
{
    static called := false
    if called
        return true
    called := true
    int_pos:=-1
    main_createMenu(    {name:"HotKey generator"
                        ,function:"default_generator"}
                        ,int_pos--)
    main_createMenu(    {name:"Show conf"
                        ,function:"default_showconf"}
                        ,int_pos--)
    main_createMenu(    {name:"About"
                        ,function:"default_about"}
                        ,int_pos--)
    main_createMenu(    {name:"Reload"
                        ,function:"default_reload"}
                        ,int_pos--)
    main_createMenu(    {name:"Exit"
                        ,function:"default_exit"}
                        ,int_pos--)
    main_createMenu(    {name:"Script"
                        ,function:"default_script"
                        ,script:"to_be_defined"
                        ,user:A_UserName
                        ,location:"active"
                        ,params:"NULL"
                        ,hide:false})
    main_createMenu(    {name:"Lynk"
                        ,function:"default_link"
                        ,link:"to_be_defined"})
    return true
}
/*
default_generator
default_showconf
default_about
default_reload
default_exit
default_script
default_link
---------------
default_nothing
default_popwarning
default_poperror
default_hotkey
default_open
default_help
*/
default_generator(arg)
{
    global
    translateKey := []

    Gui, 97:Destroy

    for key,string in global_var.modifier{
        Gui, 97:Add, CheckBox, x20 y+10 v%key% gdefault_generator_checkbox, %key%
        Gui, 97:Add, Radio, yp+0 xp+70 hidden vc%key%1, Left
        Gui, 97:Add, Radio, yp+0 xp+60 hidden vc%key%2, Right
        Gui, 97:Add, Radio, yp+0 xp+60 hidden Checked vc%key%3, Any
    }

    Gui, 97:Add, Text, xp+0 hidden,

    Gui, 97:Add, Radio, y+30 x20 vchoosetypekey,
    Gui, 97:Add, Radio, y+10 x20 vchoosetreekey,

    Gui, 97:Add, Hotkey, Limit190 x50 yp-30 gdefault_generator_choosekey vtypekey
    Gui, 97:Add, TreeView, x50 yp+30 w250 gdefault_generator_choosekey vtreekey

    conf := global_var.conf
    SplitPath, conf, ,csv
    csv := csv "\key.csv"
    PreviousGui := A_DefaultGui
    Gui, 97:Default

    Loop, read, %csv%
    {
        line := StrSplit(A_LoopReadLine , ";")
        if line[1] {
            level0 := TV_Add(line[1], 0, "")
        } else if line[2] {
            if ( ( line[3] != "" ) and ( line[2] != line[3]) )
                print := line[3] " [" line[2] "]"
            else
                print := line[2]
            a := TV_Add(print, level0, "")
            translateKey[a] := line[2]
        }
    }
    Gui, %PreviousGui%:Default

    Gui, 97:Add, Button, x20 y+20, Generate
    Gui, 97:Add, Button, x+40 yp+0, Copy

    Gui, 97:Add, Edit, x20 y+10 w280 ReadOnly vhk ,
    Gui, 97:Add, Button, y+10 x270, Exit

    Gui, 97:Show,,% global_var.name " hotkey generator"
    return
97ButtonCopy:
    GuiControlGet, key, , hk
    if key
        clipboard := key
    return
97ButtonGenerate:
    GuiControlGet, istree, , choosetreekey
    GuiControlGet, istype, , choosetypekey
    if (istree)
    {
        key := translateKey[TV_GetSelection()]
        if key
            key := GetKeyName(key)
    }
    if (istype) {
        key := typekey
        if ( RegExMatch(key, "\^") ) {
            MsgBox, 0x10, Error, Push only 1 button/key
            return
        }
    }
    if ( ! key )
        return
    fstr := GetKeyName(key)
    if ( ! fstr ){
        msgbox % "Issue while checkink caracter: " key
        return
    }
    count := 0
    for key,string in global_var.modifier{
        GuiControlGet, checked, , %key%
        if checked
        {
            count +=1
            str := key
            GuiControlGet, side, , c%key%1
            if side
                str := "l" str
            else {
                GuiControlGet, side, , c%key%2
                if side
                    str := "r" str
            }
            if (str != "Win")
                str := GetKeyName(str)
            fstr := str " + " fstr
        }
    }
    if count
        GuiControl, ,hk, % fstr
    return
97GuiEscape:
97GuiClose:
97ButtonExit:
    Gui,97:Destroy
    return
}
default_showconf(arg)
{
    static conf
    static string_conf := []
    static details

    conf := global_var.conf
    admin_conf := global_var.admin_conf

    path := global_var.icoPath
    SplitPath, A_ScriptDir,  , pathminus,
    SplitPath, path, color, path,
    if ( ( path = pathminus "\build\icons" )
      or ( path = pathminus "\build" )
      or ( path = pathminus "\icons" )
      or ( path = A_ScriptDir "\icons" )
      or ( path = pathminus )
      or ( path = A_ScriptDir ) )
        ico := color
    else
        ico := global_var.icoPath

    string_conf["Detailed conf"] := "#icons`t" ico "`r`n`r`n"
    string_conf["Full conf"] := "#icons`t" global_var.icoPath "`r`n`r`n"

    if ( ico = "blue" )
        string_conf["Simple conf"] := ""
    else
        string_conf["Simple conf"] := "#icons`t" ico "`r`n`r`n"

    loop % global_var.nb_install
    {
        key := global_var.install[A_Index]
        for i,line in default_print_menu(key,global_var.real[key], 0)
            string_conf["Simple conf"] := string_conf["Simple conf"] line "`r`n"
        for i,line in default_print_menu(key,global_var.real[key], 1)
            string_conf["Detailed conf"] := string_conf["Detailed conf"] line "`r`n"
        for i,line in default_print_menu(key,global_var.real[key], 2)
            string_conf["Full conf"] := string_conf["Full conf"] line "`r`n"
    }
    for key,val in global_var.avail
    {
        if ((val.pos = 0) and (val.nb = 0 or val.error))
        {
            string_conf["Simple conf"] := string_conf["Simple conf"] "# " key "`r`n"
            string_conf["Detailed conf"] := string_conf["Detailed conf"] "/*`r`n"
            for i,line in default_print_menu(key,val, 1)
                string_conf["Detailed conf"] := string_conf["Detailed conf"] line "`r`n"
            string_conf["Detailed conf"] := string_conf["Detailed conf"] "*/`r`n"
            string_conf["Full conf"] := string_conf["Full conf"] "/*`r`n"
            for i,line in default_print_menu(key,val, 2)
                string_conf["Full conf"] := string_conf["Full conf"] line "`r`n"
            string_conf["Full conf"] := string_conf["Full conf"] "*/`r`n"
        }
    }
    cp_conf := ""
    if global_var.use_admin{
        if (FileExist(admin_conf))
            FileRead, cp_conf, %admin_conf%
        string_conf["Current file"] := cp_conf
    } else {
        if (FileExist(conf))
            FileRead, cp_conf, %conf%
        string_conf["Current file"] := cp_conf
    }

    Gui,98:Destroy
    Gui,98:Margin,20,20
    Gui,98:Font
    Gui,98:Add,Link,y+5, Configuration stored in <a href="%conf%">%conf%</a>: `r
    if global_var.use_admin
        Gui,98:Add,Link,y+5 w300, Your current configuration is empty, the one set by the administrator is used instead (<a href="%admin_conf%">%admin_conf%</a>).

    Gui, 98:Add, Tab3,, Simple conf|Detailed conf|Full conf|Current file
    pos := "r15 w300 ReadOnly c555555"
    Gui, 98:Add, Edit, %pos%, % string_conf["Simple conf"]
    Gui, 98:Tab, 2
    Gui, 98:Add, Edit, %pos%, % string_conf["Detailed conf"]
    Gui, 98:Tab, 3
    Gui, 98:Add, Edit, %pos%, % string_conf["Full conf"]
    Gui, 98:Tab, 4
    Gui, 98:Add, Edit, %pos%, % string_conf["Current file"]
    Gui, 98:Tab
    Gui, 98:Add, Button, y+20, Copy
    Gui, 98:Add, Button, yp+0 x+20, Open
    Gui, 98:Add, Button, yp+0 x+220, Exit

    Gui, 98:Show,, % global_var.name " configuration"
    return
98ButtonCopy:
    GuiControlGet, name,, systabcontrol321
    if ( name in string_conf )
        clipboard := "#### Configuration generated by " global_var.name "`r`n`r`n" string_conf[name]
    else
        MsgBox, 0x10, Error, Tab not found: %name%
    return
98ButtonOpen:
    Run, Open %conf%
98GuiEscape:
98GuiClose:
98ButtonExit:
    Gui,98:Destroy
    return
}
default_About(arg)
{
    global tool_pic
    doc:=global_var.doc
    static id := 1

    Gui,99:Destroy
    Gui,99:Margin,20,20
    if (global_var.icos.MaxIndex() and FileExist(global_var.icos[1]))
        Gui,99:Add,Picture,xm w32 h-1 vtool_pic, % global_var.icos[1]
    Gui,99:Font,Bold
    Gui,99:Add,Text,x+10 yp+10,% global_var.name
    Gui,99:Font
    Gui,99:Add,Text,y+10, - Create customized tray with pre-defined functions
    Gui,99:Add,Text,y+5, - Create customized HotKey with pre-defined functions
    Gui,99:Add,Link,y+5, Documentation can found <a href="%doc%">here</a>
    Gui,99:Add,Link,y+5, Last release can be found in  <a href="https://github.com/cadeauthom/giftray/releases/latest">Github</a>

    url := "https://www.flaticon.com/favicon.ico"
    ico := A_Temp "\flaticon.ico"
    UrlDownloadToFile, %url%, %ico%
    if FileExist(ico)
        Gui,99:Add, Picture, xm y+20 w32 h-1, %ico%
    Gui,99:Font,Bold
    Gui,99:Add,Text,x+10 yp+10,Flaticon
    Gui,99:Font
    Gui,99:Add,Link,y+5,The images visible on the thay were initially created by <a href="https://www.flaticon.com/authors/kiranshastry">Kiranshastry</a>

    Gui,99:Font

    url := "https://www.autohotkey.com/favicon.ico"
    ico := A_Temp "\ahk.ico"
    UrlDownloadToFile, %url%, %ico%
    if FileExist(ico)
        Gui,99:Add, Picture, xm y+20 w32 h-1, %ico%
    Gui,99:Font,Bold
    Gui,99:Add,Text,x+10 yp+10,AutoHotkey
    Gui,99:Font
    Gui,99:Add,Link,y+10,This tool was made using <a href="https://www.AutoHotkey.com">AutoHotkey</a>
    Gui,99:Font
    Gui,99:Add,Link, y+5,Sound control function are part of <a href="https://autohotkey.com/board/topic/21984-vista-audio-control-functions/">VA librairy</a>

    Gui,99:Add, Picture, xm y+20 w32 h-1,
    Gui,99:Font,Bold
    Gui,99:Add,Text,x+10 yp+10,Build Information
    Gui,99:Font
    if (global_var.buildinfo.modif < 0)
        Gui,99:Add,Text, y+10, Version provided outside of scope of usual build
    else if (global_var.buildinfo.modif = 0) {
        y := "y+10"
        if (global_var.buildinfo.tag) {
            Gui,99:Add,Text, %y%, % "Release " global_var.buildinfo.tag
            y := "y+5"
        }
        Gui,99:Add,Text, %y%, % "Version based on commit " global_var.buildinfo.commit " on branch " global_var.buildinfo.branch
    } else
        Gui,99:Add,Text, y+10, % "Version based on commit " global_var.buildinfo.commit " on branch " global_var.buildinfo.branch " (" global_var.buildinfo.modif " modifed files)"
    Gui,99:Add,Text, y+5, % "Built at time " global_var.buildinfo.date

    Gui,99:Add, Button, x+200 y+20, Exit

    Gui,99:Show,, % "About " global_var.name

    if (global_var.icos.MaxIndex() > 1)
        SetTimer, LoopIco, 1000
    return
LoopIco:
    id := mod(id,global_var.icos.MaxIndex())+1
    a := global_var.icos[id]
    GuiControl,99:,tool_pic,  *w32 *h-1 %a%
    return
99GuiEscape:
99GuiClose:
99ButtonExit:
    SetTimer,LoopIco,Off
    Gui,99:Destroy
    return
}
default_reload(arg)
{
    reload
    sleep 1000
    ;msgBox, 4, , The script could not be reloaded and will need to be manually restarted. Would you like Exit?
    ;ifMsgBox, yes, exitApp
    return
}
default_exit(arg)
{
    exitApp
}
default_link(args, test:=0)
{
    error_msg := ""
    if (args["link"])
        link := args["link"]
    else
        error_msg := error_msg "Error, link not configured" "`r`n"
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    Run, %link%
}
default_script(args, test:=0)
{
    error_msg := ""
    if (args["script"])
        script := args["script"]
    else
        error_msg := error_msg "Error, script not configured" "`r`n"
    if (args["params"])
        params := args["params"]
    else
        error_msg := error_msg "Error, params not configured" "`r`n"
    if (args["hide"] != "")
        hide := args["hide"]
    else
        error_msg := error_msg "Error, hide not configured" "`r`n"
    if (args["user"])
        user := args["user"]
    else
        error_msg := error_msg "Error, user not configured" "`r`n"
    if (args["location"])
        location := args["location"]
    else
        error_msg := error_msg "Error, location not configured" "`r`n"
    if (location = "active")
        location := main_GetCurrentPath()
    else if (location = "script")
        SplitPath, script, , location, ,
    if ((location = "") or (FileExist(script) != "D"))
        location := A_MyDocuments
    path := main_GetPath(script)
    if path
        script := path
    else
        error_msg := error_msg "Error, script seems to not exist: " script "`r`n"

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    nb_loop := RegExMatch(script, "%(\w+)%", p)
    loop %nb_loop% {
        i := % p%A_index%
        EnvGet, env, %i%
        script := RegExReplace(script, "%" i "%", env )
    }
    if (params != "NULL")
        script := script " " params
    if (hide = 0)
        hide := ""
    else
        hide = "hide"
    Run, %script%, %location% , %hide%
    return
}
default_nothing(arg)
{
    return
}
default_popwarning(arg)
{
    for i,m in global_var.real
    {
        if ( m.print = A_ThisMenuItem )
            msgBox % """" m.confprint """ is not a clickable menu.`nPlease use the HotKey only to use this tool."
    }
    return
}
default_poperror(arg)
{
    msgBox % """" A_ThisMenuItem """ is not well defined: `r" arg.error
    return
}
default_hotkey(arg)
{
    ListHotkeys
    msgBox % listekey
    return
}
default_open(arg)
{
    listLines
    return
}
default_help(arg)
{
    splitpath, a_ahkPath, , ahk_dir
    run, % ahk_dir "\AutoHotkey.chm"
    return
}

;internal functions -----------------------------------------------
default_generator_checkbox(CtrlHwnd)
{
    GuiControlGet, name, name, %CtrlHwnd%
    GuiControlGet, show, , %CtrlHwnd%
    GuiControl, Show%show%, c%name%1,
    GuiControl, Show%show%, c%name%2,
    GuiControl, Show%show%, c%name%3,
    return
}
default_generator_choosekey(CtrlHwnd)
{
    GuiControlGet, name, name, %CtrlHwnd%
    GuiControl, , choose%name%, 1
    return
}
default_print_menu(m,tmp,details)
{
    str := [m " {"]
    fct := tmp.function
    if ( (details > 1) or (tmp.function != global_var.avail[fct].function) or (m != tmp.function)) {
        str.push("`tfunction : " tmp.function)
    }
    if ( (details > 1) or (tmp.ico != global_var.avail[fct].ico)) {
        f_ico := tmp.ico
        splitpath, f_ico, ico, ico_dir
        if (ico_dir = global_var.icoPath)
            str.push("`tico : " tmp.ico)
        else
            str.push("`tico : " ico)
    }
    if ( (details > 1) or ( (tmp.confprint) and (tmp.confprint != global_var.avail[fct].print) ) ) {
        if tmp.confprint
            str.push("`tprint : " tmp.confprint)
        else
             str.push("`tprint : " global_var.avail[fct].print)
    }
    if (details or (tmp.hhk != global_var.avail[fct].hhk)) {
        str.push("`tahk : " tmp.hhk)
    }
    if (details or (tmp.menu != global_var.avail[fct].menu)) {
        if tmp.menu = 1
            str.push("`tmenu : true")
        else
            str.push("`tmenu : false")
    }
    for k,w in tmp.arg
        if ( details or w != global_var.avail[fct].arg[k] )
            str.push("`t" k " : " w)
    str.push("}")
    if (str.MaxIndex() = 2)
        return [m]
    return str
}
