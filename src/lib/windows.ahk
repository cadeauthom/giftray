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
windows_init()
{
    static called := false
    if called
        return
    called := true
    main_createMenu(    {name:"Always on Top"
                        ,function:"windows_WinAlwaysontop"
                        ,hhk:"Win + SPACE"
                        ,not_in_menu:1})
    main_createMenu(    {name:"Reload Microphone"
                        ,function:"windows_ReloadMic"
                        ,hhk:"Ctrl + Win + m"
                        ,mode:"regedit/wmic"})
    main_createMenu(    {name:"Allow hibernation"
                        ,function:"windows_addHibernate"})
    main_createMenu(    {name:"Mute/Unmute"
                        ,function:"windows_MuteUnmute"
                        ,hhk:"Win + <"
                        ,device:"Capture/Playback"})
    main_createMenu(    {name:"Volume Change"
                        ,function:"windows_volume"
                        ,hhk:"Alt + NumpadSub" ;NumpadAdd
                        ,quick:1
                        ,not_in_menu:1
                        ,device:"Capture/Playback"
                        ,direction:"Up/Down"})

    return
}
windows_volume(args, test:=0)
{
    error_msg := ""
    if args["device"]
        device := args["device"]
    else
        error_msg := error_msg "Error, device not configured (Capture/Playback)" "`r`n"
    if ! VA_GetMasterVolume("",device)
        error_msg := error_msg "Error, device """ device """ not found (Capture/Playback)" "`r`n"
    if args["direction"]
        direction := args["direction"]
    else
        error_msg := error_msg "Error, direction not configured (Up/Down)" "`r`n"
    StringLower, direction, direction , T
    if ( direction = "Up" )
        change = 2
    else if ( direction = "Down" )
        change = -2
    else
        error_msg := error_msg "Error, direction """ direction """ not authorized (Up/Down)" "`r`n"
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    VA_SetMasterVolume(VA_GetMasterVolume("",device)+change,"",device)
    return
}
windows_MuteUnmute(args, test:=0)
{
    error_msg := ""
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    device_name := VA_GetDeviceName(VA_GetDevice("Capture"))
    toMute := VA_GetMasterMute( "Capture")
    if toMute
    {
        toMute := 0
        str := "Unmute"
    } else {
        toMute := 1
        str := "Mute"
    }
    VA_SetMasterMute( toMute , "Capture")
    return str " " device_name
}
windows_addHibernate(args, test:=0)
{
    error_msg := ""
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    Try {
        RunWait, *RunAs C:\Windows\System32\powercfg.exe /hibernate on
        return "Allow hibernation"
    }
    catch
        return "Fail to allow hibernation"
}
windows_WinAlwaysontop(args, test:=0)
{
    error_msg := ""
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    Winset, Alwaysontop, , A
    return
}
windows_ReloadMic(args, test:=0)
{
    error_msg := ""
    if (args["mode"] and ( (args["mode"] = "regedit") or (args["mode"] = "wmic") ))
        mode := args["mode"]
    else
        error_msg := error_msg "Error, mode not configured (regedit/wmic)" "`r`n"
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    time := 1000
    if ( mode = "wmic" ) {
        cmd := main_GetPath("wmic")
        cmd := cmd " path Win32_PnpEntity"
        filter := " where ""Service='usbaudio' and Status='OK'"""
        action := " get DeviceID"
        out := main_ExecScript(cmd filter action)
        filter := ""
        Loop, parse, out, `n, `r
        {
            key:=A_LoopField
            key:=RegExReplace(key,"^\s+")
            key:=RegExReplace(key,"\s+$")
            if (key = "")
                continue
            if (key = "DeviceID")
                continue
            key:=RegExReplace(key,"\\","\\")
            filter := filter "DeviceID='" key "' or "
        }
        if filter
        {
            filter := RTrim(filter, " or ")
            filter := " where """ filter """"
            action := " call disable"
            RunWait, *RunAs %cmd% %filter% %action%
            sleep time
            action := " call enable"
            RunWait, *RunAs %cmd% %filter% %action%
        }
    } else if ( mode = "regedit" ) {
        SplitPath, A_ScriptFullPath, , , , name_no_ext
        file := A_Temp "\" name_no_ext "_" A_ThisFunc ".reg"
        hkey := "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"
        hkey_s := """" hkey """"
        if FileExist(file)
            FileDelete % file
        Try RunWait, *RunAs C:\Windows\regedit.exe /e %file% %hkey_s%
        sleep time
        key := ""
        keys := []
        activated := false
        if not FileExist(file)
            return
        Loop, Read, %file%
        {
            line:=A_LoopReadLine
            if (line = "")
                continue
            if ( RegExMatch(line, "^\[") )
            {
                if ( RegExMatch(line, "(\{.*\})]", k) )
                {
                    key := k1
                    activated := false
                    init := true
                    properties := false
                } else if ( RegExMatch(line, key "\\Properties]") )
                {
                    properties := true
                    init := false
                } else
                {
                    properties := false
                    init := false
                }
                continue
            }
            if ( key = "" )
                continue
            if ( RegExMatch(line, "^""") )
            {
                if init
                {
                    if ( RegExMatch(line, "^""DeviceState""") )
                    {
                        if ( RegExMatch(line, "00000001") )
                            activated := true
                        else
                            activated := false
                    }
                    continue
                }
                if ( not activated )
                    continue
                if properties
                {
                    if ( RegExMatch(line, ",24""=""USB""") )
                        keys.push(key)
                    continue
                }
            }
        }
        FileDelete % file
        Loop, % 2
        {
            text := "Windows Registry Editor Version 5.00`r`r"
            line2 := """DeviceState""=dword:0000000" A_Index - 1 "`r`r"
            line2 := """DeviceState""=dword:0000000" 2 - A_Index "`r`r"
            for i,k in keys
                text := text "[" hkey "\" k "]`r" line2
            FileAppend, %text%, %file%
            Try RunWait, *RunAs C:\Windows\regedit.exe /s %file%
            sleep time
            FileDelete % file
        }
    }
    return "Reload microphone by """ %mode% """ method"
}