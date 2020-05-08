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
android_init()
{
    static called := false
    if called
        return
    called := true
    opt := {scrcpy:"Null"
           ,nmap:"nmap"
           ,port:"5555"
           ,ip:"Null"
           ,network:"all"}
    main_createMenu(   {name:"Connect phone"
                       ,function:"android_connect"
                       ,scrcpy:"Null"
                       ,nmap:"nmap"
                       ,port:"5555"
                       ,ip:"Null"
                       ,network:"all"})
    return
}

android_connect(args, test:=0)
{
    error_msg := ""
    if (args["scrcpy"])
        scrcpy := args["scrcpy"]
    else
        error_msg := error_msg "Error, scrcpy not configured" "`r`n"
    if (args["nmap"])
        nmap := args["nmap"]
    else
        error_msg := error_msg "Error, nmap not configured" "`r`n"
    if (args["port"])
        port := args["port"]
    else
        error_msg := error_msg "Error, port not configured" "`r`n"
    if (args["ip"])
        ip := args["ip"]
    else
        error_msg := error_msg "Error, ip not configured" "`r`n"
    if (args["network"])
        network := args["network"]
    else
        error_msg := error_msg "Error, network not configured" "`r`n"
    path := main_GetPath(scrcpy)
    if path
        scrcpy := path
    else
        error_msg := error_msg "Error, scrcpy seems to not exist: " scrcpy "`r`n"
    SplitPath, scrcpy, short, dir, , no_ext
    adb := dir "\adb.exe"
    path := main_GetPath(adb)
    if path
        adb := path
    else
        error_msg := error_msg "Error, adb seems to not exist: " adb "`r`n"
    nm := main_GetPath(nmap)
    if not nm
        error_msg := error_msg "Error, nmap not found: " nmap "`r`n"
    nmap := nm

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    main_ExecScript(adb " start-server")
    out := main_ExecScript(adb " devices")
    connected := 0
    Loop, parse, out, `n, `r
    {
        if (RegExMatch(A_LoopField, "device$"))  {
            connected := 1
            break
        }
    }
    if (connected = 0) {
        ips := []
        if (ip = "Null") {
            ;get ips from ipconfig
            netsh := main_GetPath("netsh")
            if (network = "all")
                out := main_ExecScript("""" netsh """ interface ip show addresses")
            else
                out := main_ExecScript("""" netsh """ interface ip show addresses " network)
            Loop, parse, out, `n, `r
            {
                if (RegExMatch(A_LoopField, "([0-9\.]+/[0-9]+)", i))
                {
                    if (RegExMatch(i, "127\.0\.0"))
                        continue
                    ips.push(i)
                }
            }
        } else {
            if (RegExMatch(ip, "/")) {
                ips.push(ip)
            }
        }
        theip := ""
        tmpip := ""
        if (ips.MaxIndex()){
            for n,i in ips {
                if theip
                    break
                out := main_ExecScript(nmap " -p " port " " i)
                Loop, parse, out, `n, `r
                {
                    if (RegExMatch(A_LoopField, "Nmap scan report for (.*)$", tmp)) {
                        tmpip := tmp1
                        continue
                    }
                    if (RegExMatch(A_LoopField, "5555/tcp\s+open")) {
                        theip := tmpip
                    }
                    if theip
                        break
                }
            }
        } else {
            ; TODO: check port is opened
            theip := ip
        }
        if theip {
            out := main_ExecScript(adb " connect " theip ":" port)
            connected := 1
            Loop, parse, out, `n, `r
            {
                if (RegExMatch(A_LoopField, "cannot"))  {
                    connected := 0
                    break
                }
            }
        } else
            return "No devices with " port " port opened"
    }
    if (connected = 1)
    {
        Run, %scrcpy%
        return "Connect device"
    }
    return "Fail to find device to connect"
}