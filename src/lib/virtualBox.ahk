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
virtualBox_init()
{
    static called := false
    if called
        return true
    called := true

    main_createMenu(    {name:"Start Local Cluster"
                        ,function:"virtualBox_startLocalCluster"
                        ,hhk:"Win + c"
                        ,vms:"my-vm01,my-vm02"
                        ,vboxmanage:"VBoxManage.exe"})
    main_createMenu(    {name:"Kill VMs"
                        ,function:"virtualBox_KillVMs"
                        ,hhk:"Ctrl + Win + c"
                        ,vms:"all"
                        ,vboxmanage:"VBoxManage.exe"})
    return
}

virtualBox_startLocalCluster(args, test:=0)
{
    error_msg := ""
    if (args["vms"])
        vms := StrReplace(args["vms"] , ",", " ")
    else
        error_msg := error_msg "Error, list of VMs not configured" "`r`n"
    if (args["vboxmanage"])
        vboxmanage := args["vboxmanage"]
    else
        error_msg := error_msg "Error, vboxmanage not configured" "`r`n"
    vbox := main_GetPath(vboxmanage)
    if (not vbox)
        error_msg := error_msg "Error, vboxmanage not found: " vboxmanage "`r`n"

    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }

    RunWait, %vbox% startvm --type headless %vms%
    return "Started " vms
}
virtualBox_KillVMs(args, test:=0)
{
    error_msg := ""
    if (args["vboxmanage"])
        vboxmanage := args["vboxmanage"]
    else
        error_msg := error_msg "Error, vboxmanage not configured" "`r`n"
    vbox := main_GetPath(vboxmanage)
    if (not vbox)
        error_msg := error_msg  "Error, vboxmanage not found: " vboxmanage "`r`n"
    if (error_msg or test)
    {
        if not test
            msgbox % error_msg
        return error_msg
    }
    msg :=""
    if (args["vms"])
        vms := StrSplit(args["vms"] , ",")
    for id, element in vms
        if element := "all" {
            vms := GetVMs(vbox)
            break
        }
    if (vms.MaxIndex()>0)
    {
        str := "You are trying to kill VMs :"
        liste_vms := ""
        for id, element in vms
            liste_vms .= "`n`t" . element
        str .= str liste_vms "`nForce poweroff ? (no means ACPI, force after 6sec)"
        MsgBox, 0x133, ,%str%, 10
        IfMsgBox Cancel
            return 0
        IfMsgBox TimeOut
            return 0
        IfMsgBox No
        {
            opt := "acpipowerbutton"
            msg := "Sent " opt " to:" liste_vms
            for id, vm in vms
                RunWait, %vbox% controlvm %vm% %opt%
            Sleep, 6000
            vms := GetVMs(vbox)
        }
        opt := "poweroff"
        if (vms.MaxIndex()>0)
        {
            liste_vms := ""
            for id, element in vms
                liste_vms .= "`n`t" . element
            msg := msg "`nSent " opt " to:" liste_vms
            for id, vm in vms
                RunWait, %vbox% controlvm %vm% %opt%
        }
    }
    return msg
}

; ------- internal functions ---------------------------------------------------
GetVMs(vbox)
{
    rvms := main_ExecScript("""" vbox """ list runningvms")
    vms := []
    Loop, parse, rvms, `n, `r
    {
        if (RegExMatch(A_LoopField, """(.*)""", vm))
        {
            vms.push(vm1)
        }
    }
    return vms
}