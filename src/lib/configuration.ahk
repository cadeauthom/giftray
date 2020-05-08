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
configuration_initialisation()
{
    configuration_readconf(global_var.conf)
    if (global_var.nb_install = 0) {
        configuration_readconf(global_var.admin_conf)
        global_var.use_admin := true
    }
}
configuration_readconf(file)
{
    conf_hash := {}
    current := 0
    comment := 0
    tmp := {}
    if (FileExist(file))
    {
        configuration_init_empty_menu(tmp)
        Loop, Read, %file%
        {
            key:=A_LoopReadLine
            key:=RegExReplace(key,"^\s+")
            key:=RegExReplace(key,"\s+$")
            if (key = "")
                continue
            if ( RegExMatch(key, "^\/\*")) {
                comment := 1
            }
            if comment {
                if ( RegExMatch(key, "\*\/$"))
                    comment := 0
                continue
            }
            if ( RegExMatch(key, "^#include\s+(.*)$", p)) {
                while RegExMatch(p1, "^(\S*)\s+(.*)$", q){
                    p1 := q2
                    if (not conf_hash[q1]) {
                        configuration_ConfigureMenuInclude(q1)
                        conf_hash[q1] := 1
                    }
                }
                if (not conf_hash[p1]) {
                    configuration_ConfigureMenuInclude(p1)
                    conf_hash[p1] := 1
                }
                continue
            }
            first := SubStr(key, 1 , 1)
            boolinit := RegExMatch(key, "(\w+)\s*{",c)
            if (boolinit and not current = 0)
                continue
            if (first = "}" and current = 0)
                continue
            if (boolinit) {
                current := c1
                continue
            }
            if (first = "}") {
                configuration_build_menu(current,tmp)
                current := 0
                configuration_init_empty_menu(tmp)
                continue
            }
            if (RegExMatch(first, "\W"))
                continue
            if (not current = 0) {
                configuration_read_line(key,tmp)
                continue
            }
            configuration_build_menu(key,{})
        }
    }
}
configuration_build_menu(m,tmp){
    if (!tmp.arg)
        configuration_init_empty_menu(tmp)
    if (tmp.function = "")
        tmp.function := m
    if ( (m = "") or (tmp.function = "") ) {
        configuration_set_error(m, m " function is not defined")
        return
    }
    if (not global_var.avail[tmp.function]) {
        configuration_set_error(m, "Function " tmp.function " does not exist")
        return
    }
    if (global_var.avail[tmp.function].pos < 0) {
        configuration_set_error(m, "Function " tmp.function " is a default one")
        return
    }
    if (global_var.real[m])
        configuration_add_error(tmp, "Function " tmp.function " already in use with same name ")

    configuration_cp_default(tmp,global_var.avail[tmp.function])
    if ((tmp.menu = 0) and (tmp.hhk = ""))
        configuration_add_error(tmp, "Not in tray menu or ahk")
    for opt,val in tmp.arg {
        if global_var.avail[tmp.function].arg[opt] = ""
            configuration_add_error(tmp,"Error, option " opt " does not exist")
    }
    if tmp.hhk
    {
        tmp_hhk := main_validate_hhk(tmp.hhk)
        if not tmp_hhk
            configuration_add_error(tmp, tmp.hhk " has issue to be set as HotKey")
        else {
            tmp.hhk := tmp_hhk
            for k,t in global_var.real {
                if (! t.hhk)
                    continue
                if (t.hhk != tmp.hhk)
                    continue
                configuration_add_error(tmp,tmp.hhk " already in use")
            }
        }
    }
    fct := Func(tmp.function)
    err := fct.(tmp.arg,1)
    if (err)
        configuration_add_error(tmp, err)

    if (tmp.error) {
        ;before factorisation, if tmp was not input: global_var.avail[m].nb += 1
        configuration_set_error(m,tmp.error)
        return
    }

    ;before factorisation, if tmp was not input: global_var.avail[m].pos = ... and test it
    global_var.avail[tmp.function].nb += 1
    global_var.nb_install++
    tmp.pos := global_var.nb_install
    configuration_add_real(m,tmp)
    global_var.install[global_var.nb_install] := m
    return
}
configuration_add_error(tmp,err)
{
    if tmp.error
        tmp.error := tmp.error "`r`n`t-" err
    else
        tmp.error := "`t-" err
    return
}
configuration_ConfigureMenuInclude(m)
{
    file := global_var.conf ".d\" m ".conf"
    if (not FileExist(file)) {
        global_var.err["file_" m] := "Config file not found"
        return
    }
    tmp := []
    comment := 0
    configuration_init_empty_menu(tmp)
    Loop, Read, %file%
    {
        key:=A_LoopReadLine
        key:=RegExReplace(key,"^\s+")
        key:=RegExReplace(key,"\s+$")
        if (key = "")
            continue
        if ( RegExMatch(key, "^\/\*")) {
            comment := 1
        }
        if comment {
            if ( RegExMatch(key, "\*\/$"))
                comment := 0
            continue
        }
        first := SubStr(key, 1 , 1)
        if (RegExMatch(first, "\W"))
                continue
        configuration_read_line(key,tmp)
    }
    configuration_build_menu(m,tmp)
    return
}
;------------- fct endlevel
configuration_set_error(key,error)
{
    k := key
    i := 0
    while (global_var.err[k]) {
        i ++
        k := key " [" i "]"
    }
    global_var.err[k] := error
    return
}
configuration_read_line(key,tmp) {
    if (RegExMatch(key, "^([^:]+):(.*)$", opt)) {
        ;msgBox % opt1 " -- " opt2
        opt2:=RegExReplace(opt2,"\s+$")
        opt2:=RegExReplace(opt2,"^\s+")
        opt1:=RegExReplace(opt1,"\s+$")
        opt1:=RegExReplace(opt1,"^\s+")
        Switch opt1 {
            Case "function":
                tmp.function := opt2
            Case "ico":
                tmp.ico := opt2
            Case "print":
                tmp.print := SubStr(opt2,1,32)
            Case "ahk":
                if opt2
                    tmp.hhk := opt2
                else
                    tmp.hhk := "NULL"
            Case "menu":
                if ((opt2 = "1") or (opt2 = "true"))
                    tmp.menu := 1
                else
                    tmp.menu := -1
            Default:
                tmp.arg[opt1] := opt2
        }
    } else {
        tmp.arg[key] := 1
    }
}
configuration_init_empty_menu(tmp)
{
    tmp.function := ""
    tmp.ico := ""
    tmp.pos := 0
    tmp.print := ""
    tmp.hhk := ""
    tmp.menu := 0
    tmp.error := ""
    tmp.arg := []
    tmp.quick := 0
}
configuration_cp_default(tmp,orig)
{
    if ( !tmp.function )
        tmp.function := orig.function
    if ( !tmp.ico )
        tmp.ico := orig.ico
    else {
        if (SubStr(tmp.ico, 1 , 1) = ".")
            tmp.ico := A_ScriptDir  SubStr(tmp.ico, 2)
        else
            if (not SubStr(tmp.ico, 2 , 1) = ":")
                tmp.ico := global_var.icoPath  tmp.ico
        if (not FileExist(tmp.ico))
            tmp.ico := orig.ico
    }
    ;tmp.pos ; stay to 0
    if ( !tmp.print )
        tmp.print := orig.print
    if ( !tmp.hhk )
        tmp.hhk := orig.hhk
    if ( tmp.hhk = "NULL")
        tmp.hhk := ""
    if ( tmp.menu < 0)
        tmp.menu := 0
    else if ( tmp.menu = 0 )
        tmp.menu := orig.menu
    if ( orig.error )
        tmp.error := orig.error
    for opt,val in orig.arg {
        if tmp.arg[opt] = ""
            tmp.arg[opt] := val
    }
    if orig.quick
        tmp.quick := orig.quick
    return
}
configuration_add_real(m,tmp)
{
    nb := 0
    for k,t in global_var.real {
        if t.confprint = tmp.print
            nb ++
    }
    global_var.real[m]:={   function:tmp.function
                            ,ico:tmp.ico
                            ,pos:tmp.pos
                            ,print:tmp.print
                            ,confprint:tmp.print
                            ,hhk:tmp.hhk
                            ,menu:tmp.menu
                            ,quick:tmp.quick
                            ,arg:tmp.arg}
    if nb > 0
        global_var.real[m].print := Format("{:s}({:i})",global_var.real[m].print,nb)
    global_var.real[m].print:=RegExReplace(global_var.real[m].print,"&","&&")
    if (not global_var.real[m].hhk = "")
        global_var.real[m].print := Format("{:s}{:s}{:s}",global_var.real[m].print,A_Tab,global_var.real[m].hhk)
    return
}