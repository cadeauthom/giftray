#SingleInstance force
#NoTrayIcon
SetWinDelay, -1

#Include <setup_built>

;-------------INIT
project := "rainette"

if A_Args.MaxIndex()
    thisuser := A_Args[1]
else
    thisuser := A_UserName

setup_admin(thisuser)

;-------------GUI
Gui,Destroy
    
Gui,Margin,10,10
Gui,Add,Picture,xm Icon1,%A_ScriptName%.exe
Gui,Font
Gui, Add, Text, y0 x0 Hidden vproj, %project%
Gui, Add, Text, y0 x0 Hidden vuser, %thisuser%
Gui, Add, Text, y0 x0 Hidden vexe, 
Gui, Add, Text, y0 x0 Hidden vstatus, OK
Gui,Add,Text, yp+15 x10 vtext, Welcome to the installation wizard of %project%
Gui,Add,Text, yp+15 x10 W250 vtext0, 
Gui,Add,Text, yp+15 x10 W250 vtext1,
Gui, Add, CheckBox, yp+0 x30 Checked vmenu, Add menu in start
Gui,Add,Text, yp+15 x10 W250 vtext2, 
Gui, Add, CheckBox, yp+0 x30 Checked vconf, Keep configuration
Gui,Add,Text, yp+15 x10 W250 vtext3, 
Gui, Add, CheckBox, yp+0 x30 Checked vboot, Start %project% when system starts


Gui, Add, Progress, yp+25 x10 w350 h20 Hidden BackgroundWhite vprogress, 100
Gui, Add, Edit, yp+0 x10 R1 W250 vdir, %a_ProgramFiles%\%project%
Gui, Add, Button, x+1 yp-1 vbbrowse, Browse
Gui, Add, Button, x+1 yp+0 vbdefault, Default

Gui, Add, Button, yp+40 x10 vbinstall, Install
Gui, Add, Button, yp+0 x10 hidden vbstart, Start
Gui, Add, Button, yp+0 x+20 vbremove, Remove
Gui, Add, Button, yp+0 x+220 vbexit, Exit

Gui,Show,,%project% installation
;hCurs:=DllCall("LoadCursor","UInt",NULL,"Int",32649,"UInt") ;IDC_HAND
;OnMessage(0x200,"WM_MOUSEMOVE")

return

;-------------SUB
ButtonStart:
    GoSub initval
    run, %exe%
    return
ButtonDefault:
    GoSub initval
    GuiControl,, dir , %a_ProgramFiles%\%proj%
    return
ButtonBrowse:
    GoSub initval
    FileSelectFolder, SelectedDir, 2, %dir%, Installation Folder
    GuiControl,, dir , %SelectedDir%\%proj%
    return
ButtonInstall:
    GoSub hideall
    GoSub ButtonRemove
    GoSub initval
    if (status = "KO")
        return
    GuiControl, , text0, 1/3 - Decompression
    GuiControl, , progress, 0
    installdir := setup_built_install()
    GuiControl, , text1, 2/3 - Installation
    GuiControl, , progress, 0
    FileCopyDir, %installdir%, %dir%, 0 ; do not overwrite
    ;TODO copy this to path
    exe_path := setup_built_shortcut(dir, boot, menu)
    GuiControl, , exe, exe_path
    GuiControl, , text2, 3/3 - Clean up
    GuiControl, , progress, 0
    FileRemoveDir, %installdir%, 1 ; recursive
    GuiControl, , progress, 100
    GuiControl, , text3, Installation complete
    GuiControl, show, bstart 
    return
ButtonRemove:
    GoSub hideall
    GoSub initval
    ;if not setup_is_an_installation(dir)
    ;    return
    if not setup_kill_previous(project) {
        GuiControl, , text, Fail to stop previous instance of %project%
        GuiControl, , text0, Please stop manually before installing
        GuiControl, , text1, Installation canceled
        GuiControl, , status, KO
        return
    }
    GuiControl, , text, 1/1 - Remove previous version
    if conf
        confsave := setup_built_save_conf(dir)
    ;FileRemoveDir, %dir%\, 1
    setup_recursive_rm(dir)
    if conf {
        FileCopyDir, %confsave%, %dir%, 1
        FileRemoveDir, %confsave%, 1 ; recursive
    }
    setup_built_rm_start()
    GuiControl, , text, Uninstallation complete
    return
ButtonExit:
GuiEscape:
GuiClose:
    Gui,Destroy
    ExitApp
initval:
    GuiControlGet, dir
    GuiControlGet, conf
    GuiControlGet, boot
    GuiControlGet, menu
    GuiControlGet, proj
    GuiControlGet, user
    GuiControlGet, status
    return
hideall:
    GuiControl, Hide, dir
    GuiControl, Hide, conf
    GuiControl, Hide, boot
    GuiControl, Hide, menu
    GuiControl, Hide, bbrowse
    GuiControl, Hide, bdefault
    GuiControl, Hide, binstall
    GuiControl, Hide, bremove
    GuiControl, , text,
    GuiControl, , text0,
    GuiControl, , text1,
    GuiControl, , text2,
    GuiControl, , text3,
    GuiControl, Show, progress
    ;GuiControl, Hide, bcancel
    return

;-------------FCT
setup_admin(user)
{
    if not (A_IsAdmin)
    {
        try Run *RunAs %A_ScriptFullPath% %user%
        exitApp
    }
    return
}
setup_kill_previous(process)
{
    Process,Exist, %process%.exe
    if Errorlevel {
        MsgBox, 0x21, %process%, Kill %process% ?
        IfMsgBox, OK
        {
            Process, waitclose, %process%.exe; 10
            if errorlevel
                return 0
        } else
            return 0
    }
    return 1
}
setup_recursive_rm(dir)
{
    msgbox % dir
    Loop Files, %dir%\*, F
        FileDelete, % dir "\" A_LoopFileName
    Loop Files, %dir%\*, D
        setup_recursive_rm(dir "\" A_LoopFileName)
    FileRemoveDir, %dir%\
    return
}