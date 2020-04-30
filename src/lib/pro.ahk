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
pro_init()
{
    static called := false
    if called
        return
    called := true
    main_createMenu(    "Unconnect pro"
                        ,"pro_unconnectpro"
                        ,"Ctrl + Win + BS")

    opt := {veracrypt:"veracrypt.exe"}
    main_createMenu(    "Umount All"
                        ,"pro_umountAll"
                        ,"Ctrl + Win + ²"
                        ,opt)
    opt := {drive:"v"
           ,path:"C:\my.vc"
           ,veracrypt:"veracrypt.exe"}
    main_createMenu(    "Mount V"
                        ,"pro_mountV"
                        ,"Win + ²"
                        ,opt)
    return
}

pro_mountV(args, test:=0)
{
    error_msg := ""
    if (args["path"])
        path := args["path"]
    else
        error_msg := error_msg "Error, Path not configured" "`r`n"
    if (args["drive"])
        drive := args["drive"]
    else
        error_msg := error_msg "Error, drive not configured" "`r`n"
    if (args["veracrypt"])
        veracrypt := args["veracrypt"]
    else
        error_msg := error_msg "Error, veracrypt not configured" "`r`n"
    vc := main_GetPath(veracrypt)
    if (not vc)
        error_msg := error_msg "Error, veracrypt not found: " veracrypt "`r`n"

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    RunWait, %vc% /v %path% /l %drive% /q /securedesktop
    return "Tried to mount " path " as " drive
}
pro_umountAll(args, test:=0)
{
    error_msg := ""
    if (args["veracrypt"])
        veracrypt := args["veracrypt"]
    else
        error_msg := error_msg "Error, veracrypt not configured" "`r`n"
    vc := main_GetPath(veracrypt)
    if (not vc)
        error_msg := error_msg "Error, veracrypt not found: " veracrypt "`r`n"

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    MsgBox, 0x24, , Umount all ?
    IfMsgBox Yes
    {
        /*
        pre_func:="virtualBox_KillVMs"
        if IsFunc(pre_func)
        {
            if (%pre_func%() < 0)
                return
        }
        */
        RunWait, %vc% /q /d
        return "Unmout all Drive"
    }
    return
}

pro_unconnectpro(args, test:=0)
{
    error_msg := ""

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    app2close := []
    for index, element in app2close
    {
        Process, Exist, %element%
        if (errorlevel)  {
            Process, Close , errorlevel
            msgbox % element
        }
    }
    Process, Exist, TeamViewer.exe
    net := main_GetPath("C:\Windows\System32\net.exe")
    if (errorlevel)
        if not A_IsAdmin
            Try RunWait, *RunAs %net% stop TeamViewer /y
    Process, Exist, CrashPlanDesktop.exe
    if (errorlevel)
        if not A_IsAdmin
            Try RunWait, *RunAs %net% stop CrashPlanService /y
    Process, Exist, OneDrive.exe
    if (errorlevel)
        onedrive := main_GetPath("C:\Users\tcadeau\AppData\Local\Microsoft\OneDrive\OneDrive.exe")
        if onedrive
            RunWait, %onedrive% /shutdown
    return
}

