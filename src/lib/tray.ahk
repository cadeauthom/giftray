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
tray_initialisation()
{
    Menu, Tray, NoStandard
    if global_var.nb_install > 0
    {
        loop % global_var.nb_install
        {
            ;i := global_var.nb_install - A_Index + 1
            i := A_Index
            key := global_var.install[i]
            if global_var.real[key].menu
            {
                tray_addMenu("Tray"
                            ,global_var.real[key].print
                            ,global_var.real[key].function
                            ,global_var.real[key].ico
                            ,global_var.real[key].arg
                            ,global_var.real[key].confprint)
            }
            if global_var.real[key].hhk != ""
            {
                hk := global_var.real[key].hhk
                func := % global_var.real[key].function
                tray_DefineHotKey(hk, func, global_var.real[key].arg,global_var.real[key].confprint)
            }
        }
        Menu, Tray, Add
    }
    not_menu:=0
    not_installed:=0
    for key,val in global_var.avail
    {
        if val.pos = 0 and val.nb = 0
        {
            not_installed:=1
            tray_addMenu("notinstall_menu"
                        ,val.print
                        ,"default_nothing"
                        ,val.ico
                        ,[])
        }
        else if 0 and not val.menu
        {
            not_menu:=1
            tray_addMenu("not_menu"
                        ,val.print
                        ,"default_popwarning"
                        ,val.ico
                        ,[])
        }
    }
    for key,val in global_var.real
    {
        if not val.menu
        {
            not_menu:=1
            tray_addMenu("not_menu"
                        ,val.print
                        ,"default_popwarning"
                        ,val.ico
                        ,[])
        }
    }
    if not_menu = 0
    {
        tray_addMenu("not_menu","Empty","default_nothing",global_var.empty_ico,[])
    }
    if not_installed = 0
    {
        tray_addMenu("notinstall_menu","Empty","default_nothing",global_var.empty_ico,[])
    }
    Menu, Tray, Add, Inactive, :notinstall_menu
    Menu, Tray, Add, Not clickable, :not_menu
    has_error := 0
    for m,msg in global_var.err {
        tray_addMenu("error_menu",m,"default_poperror",global_var.default_ico,{error:msg})
        has_error := 1
    }
    if ! has_error
    {
        tray_addMenu("error_menu","Empty","default_nothing",global_var.empty_ico,[])
    }
    Menu, Tray, Add, In Error, :error_menu
    Menu, Tray, Add

    loop % global_var.nb_default
    {
        i := - A_Index
        key := global_var.install[i]
        tray_addMenu("Tray"
                    ,global_var.avail[key].print
                    ,global_var.avail[key].function
                    ,global_var.avail[key].ico
                    ,[])
    }
    Menu, Tray, Tip, % global_var.name
}

;------------------------------------------------------------
tray_DefineHotKey(hk, fun, arg, print:=0)
{
    hk :=   {type:"hk"
            ,fun:fun
            ,hk:hk
            ,arg:arg
            ,print:print}
    tray_Wrapper(hk)
    return
}
tray_addMenu(tray, key, fun, ico, arg, print:=0)
{
    menu := {type: "menu"
            ,tray:tray
            ,fun:fun
            ,key:key
            ,ico:ico
            ,arg:arg
            ,print:print}
    tray_Wrapper(menu)
    return
}
tray_Wrapper(fn)
{
    Static funs := {}
    Static args := {}
    Static info := {}
    Static time := 400
    Static id := 1
    Static nb := 6
    if (not fn)
        return
    fun := fn.fun
    arg := fn.arg
    if (fn.type = "menu")
    {
        key := fn.key
        tray := fn.tray
        ico := fn.ico
        if ( not IsLabel(fun) and not IsFunc(fun) )
            fun := "default_nothing"
        key := RegExReplace(key, "&$", "&&")
        Menu, %tray%, Add, %key%, MenuHandle
        if ( fun = "default_nothing" )
            Menu, %tray%, Disable, %key%
        if ( ico = "222" or ico = "294" )
            Menu, %tray%, Icon, %key%, shell32.dll, %ico%
        else
            Menu, %tray%, Icon, %key%, %ico%
     }
    else if (fn.type = "hk")
    {
        hk := fn.hk
        key := main_string_to_key(hk)
        if (! key)
            return
        try
            Hotkey, %key%, HKHandle
        catch {
            MsgBox, 0x10, Error, Hotkey threw an exception: "%hk%" is not well configured for "%fun%"
        }
    }
    if key
    {
        if fn.print
            info[key] := fn.print
        else
            info[key] := fn.key
        funs[key] := Func(fun)
        args[key] := arg
    }
    return
MenuHandle:
    if (global_var.icos.MaxIndex() > 1)
        SetTimer, WrapperLoopIco, %time%
    key := A_ThisMenuItem
    GoSub WrapperHandle
    return
HKHandle:
    if (global_var.icos.MaxIndex() > 1)
        SetTimer, WrapperLoopIco, %time%
    key := A_ThisHotkey
    GoSub WrapperHandle
    return
WrapperHandle:
    msg := funs[key].(args[key])
    if msg
    {
        Menu Tray, NoIcon
        Menu Tray, Icon
        TrayTip, % info[key], % msg, , 0x30
    }
    SetTimer,WrapperLoopIco,Off
    if (global_var.icos.MaxIndex() > 1)
    {
        Loop, % max(nb - id, 0)
        {
            Sleep, % time
            GoSub WrapperLoopIco
        }
        Sleep, % time
        Menu, Tray, Icon, % global_var.icos[1] , 1
    }
    Return
WrapperLoopIco:
    id := mod(id,global_var.icos.MaxIndex())+1
    Menu, Tray, Icon, % global_var.icos[id] , 1
    return
}

tray_delMenu(tray, key)
{
    Menu, %tray%, Delete, %key%
}