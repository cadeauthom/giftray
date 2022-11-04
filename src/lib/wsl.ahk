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
wsl_init()
{
    static called := false
    if called
        return
    called := true

    main_createMenu(    {name:"Terminator"
                        ,function:"wsl_terminator"
                        ,hhk:"Ctrl + Win + t"
                        ,vcxsrv:"vcxsrv.exe"})
    main_createMenu(    {name:"Set Proxy"
                        ,function:"wsl_setproxy"
                        ,hhk:"Ctrl + Win + p"
                        ,port:"8080"
                        ,host:"hostname"})
    return
}

wsl_setproxy(args, test:=0)
{
    error_msg := ""
    if (args["port"])
        port := args["port"]
    else
        error_msg := error_msg "Error, port not configured" "`r`n"
    if (args["host"])
        host := args["host"]
    else
        error_msg := error_msg "Error, host not configured" "`r`n"

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    cmd := "ssh -C2qTnNf " host " -D " port
    wsl := main_GetPath("C:\Windows\System32\wsl.exe")
    RunWait, %wsl% bash -c "ps aux | grep '%cmd%' |grep -v grep || %cmd%" ,,Hide
    return cmd
}
wsl_terminator(args, test:=0)
{
    error_msg := ""
    if (args["vcxsrv"])
        vcxsrv := args["vcxsrv"]
    else
        error_msg := error_msg "Error, vcxsrv not configured" "`r`n"
    vc := main_GetPath(vcxsrv)
    if (not vc)
        error_msg := error_msg "Error, vcxsrv not found: " vcxsrv "`r`n"
    vcxsrv := vc

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    SplitPath, vcxsrv, vc, , ,
    Process, Exist, %vc%
    if (!errorlevel)
        Run, %vcxsrv% :0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl -dpi auto

    path := main_GetCurrentPath()
    transformPath := % Path_Win2Lin(path)
    path := transformPath[1]
    driveW := transformPath[2]
    driveL := transformPath[3]
    if not transformPath[2] = ""
    {
        file := "~/.bash_mount_msg.sh"
        cmd := "mount | grep " driveW
        cmd := cmd " || ( ("
        cmd := cmd          "grep '" file "' ~/.bashrc "
        cmd := cmd          "|| echo -e '\nif [ -f "  file " ]; then\n\t. " file "\n\trm " file "\nfi\n' >>  ~/.bashrc "
        cmd := cmd      ")"
        cmd := cmd      " && echo 'sudo -- sh <<EOF' > " file
        cmd := cmd      " && echo mkdir -p " driveL " >> " file
        cmd := cmd      " && echo mount -t drvfs \'" driveW "\' " driveL " -o metadata >> " file
        cmd := cmd      " && echo EOF >> " file
        cmd := cmd      " && echo cd " path " >> " file
        cmd := cmd  ")"
        RunWait, C:\Windows\System32\wsl.exe bash -c "%cmd%" ,,Hide
    }
    cmd := "DISPLAY=localhost:0 terminator --working-directory=" path
    wsl := main_GetPath("C:\Windows\System32\wsl.exe")
    Run, %wsl% bash -c "%cmd%" ,, Hide
    return "Launch Terminator"
}
; ------- internal functions ---------------------------------------------------
Path_Win2Lin(win)
{
    to_return:=["~","",""] ;[linux path, win drive, linux mnt dir]
    ;default
    if ( win = "" )
        return to_return
    ;windows specific directory
    if (InStr(win, "::") = 1)
        return to_return
    ;network drive
    if (InStr(win, "\\") = 1) {
        ; take (host/dir) to mount
        a := win "\"
        l := InStr(SubStr(a,3), "\") + 1
        len := l + InStr(SubStr(a,l + 3), "\") - 1
        if (len <= l) {
            return to_return
        }
        drive := SubStr(a,3,len)
        to_return[2] := "\\" drive ""
        to_return[2] := StrReplace(to_return[2], "\", "\\\\\\\\")
        StringLower, drive, drive
        drive := StrReplace(drive, "\", "/")
        to_return[3] := "/mnt/" + drive
        path := StrReplace(SubStr(win,len+3), "\", "/")
        path := StrReplace(path, " ", "\ ")
        path := % to_return[3] path
        to_return[1] := path
        return to_return
    } else {
        drive := % SubStr(win,1,1)
        to_return[2] := SubStr(win,1,2)
        StringLower, drive, drive
        to_return[3] := "/mnt/" + drive
        path := StrReplace(SubStr(win,3), "\", "/")
        path := StrReplace(path, " ", "\ ")
        path := % to_return[3] path
        to_return[1] := path
    }
    return to_return
}
