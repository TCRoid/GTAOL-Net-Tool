/************************************************************************
 * @description GTAOL Net Tool
 * @author Rostal
 * @date 2024/11/14
 * @versio 1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance

TITLE := "GTAOL Net Tool"
GTA_TITLE := "Grand Theft Auto"

if not A_IsAdmin {
    MsgBox("你需要以管理员身份运行该程序", TITLE, "OK")
    ExitApp
}

MyGui := Gui(, TITLE)
MyGui.Opt("+Resize")

/* 创建 GUI 控件 */

MyGui.Add("Text", , "先添加防火墙规则，否则功能无效")

MyGui.Add("Button", "h32 Section", "添加防火墙规则").OnEvent("Click", addFireWallRules)

MyGui.Add("Button", "hp x+m ", "删除防火墙规则").OnEvent("Click", delFireWallRules)

MyGui.Add("Button", "hp x+m ", "打开防火墙规则设置").OnEvent("Click", openFireWallRules)

MyGui.Add("Text", "xs y+16 Section w320", "快捷键功能（Ctrl + 快捷键 为关闭功能）").SetFont("bold")

JobTeleportBtn := MyGui.Add("Checkbox", "xs y+8 w320", "[F4]  模拟 Alt + F4 差传（等待40s后返回）")
JobTeleportBtn.OnEvent("Click", JobTeleport)

DisableAllNetBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F5]  禁止 所有程序联网")
DisableAllNetBtn.OnEvent("Click", DisableAllNet)

DisableGameNetBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F6]  禁止 GTA5 联网")
DisableGameNetBtn.OnEvent("Click", DisableGameNet)

DisableGameSaveBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F7]  禁止 上传线上存档")
DisableGameSaveBtn.OnEvent("Click", DisableGameSave)

LeftMouseClickBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F8]  收集财物（点击鼠标左键）")
LeftMouseClickBtn.OnEvent("Click", LeftMouseClick)

; TestBtn := MyGui.Add("Checkbox", "xs y+32 wp", "[F3]  Test")
; TestBtn.OnEvent("Click", Test)

/* 显示窗口 */

MyGui.Show("w480 h600 Center")

/* GUI 控件 绑定事件 */

CoordMode "ToolTip"

getGamePath() {
    RegPath := "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V"
    GameFolder := RegRead(RegPath, "InstallFolderSteam", "")
    if (GameFolder) {
        GamePath := GameFolder "GTA5.exe"
        if FileExist(GamePath) {
            return GamePath
        }
    }
    return false
}

addFireWallRules(*) {
    cmdStart := 'netsh advfirewall firewall add rule '
    cmdEnd1 := ' dir=in action=block enable=no'
    cmdEnd2 := ' dir=out action=block enable=no'

    RunWait cmdStart 'name="__BLOCK_ALL__"' cmdEnd1, , "hide"
    RunWait cmdStart 'name="__BLOCK_ALL__"' cmdEnd2, , "hide"

    GamePath := getGamePath()
    if !(GamePath) {
        GamePath := "GTA5.exe"
    }
    RunWait cmdStart 'name="__BLOCK_GTA5__" program="' GamePath '"' cmdEnd1, , "hide"
    RunWait cmdStart 'name="__BLOCK_GTA5__" program="' GamePath '"' cmdEnd2, , "hide"

    RunWait cmdStart 'name="__BLOCK_GTA5_SAVING__" remoteip="192.81.241.171"' cmdEnd2, , "hide"

    if (GamePath == "GTA5.exe") {
        MsgBox("因未能找到游戏文件(GTA5.exe)，需要手动设置 `"__BLOCK_GTA5__`" 防火墙规则", "添加防火墙规则", "OK")
    } else {
        MsgBox("已成功添加防火墙规则", "添加防火墙规则", "OK")
    }
}
delFireWallRules(*) {
    cmdStart := 'netsh advfirewall firewall delete rule '
    cmdEnd1 := ' dir=in'
    cmdEnd2 := ' dir=out'

    RunWait cmdStart 'name="__BLOCK_ALL__"' cmdEnd1, , "hide"
    RunWait cmdStart 'name="__BLOCK_ALL__"' cmdEnd2, , "hide"

    RunWait cmdStart 'name="__BLOCK_GTA5__"' cmdEnd1, , "hide"
    RunWait cmdStart 'name="__BLOCK_GTA5__"' cmdEnd2, , "hide"

    RunWait cmdStart 'name="__BLOCK_GTA5_SAVING__"' cmdEnd2, , "hide"

    MsgBox("已删除防火墙规则", "删除防火墙规则", "OK")
}
openFireWallRules(*) {
    RunWait "wf.msc", , "hide"
}

PressAltF4() {
    if WinExist(GTA_TITLE) {
        PostMessage 0x112, 0xF060, , , GTA_TITLE ; 0x112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
    }
}
JobTeleport(*) {
    if !(JobTeleportBtn.Value) {
        return
    }

    PressAltF4()

    /* 等待 40s */
    index := 40
    while (index > 0) {
        if !(JobTeleportBtn.Value) {
            break
        }

        ToolTip "剩余时间: " index "s", 10, 10
        Sleep(1000)
        index -= 1
    }

    if (JobTeleportBtn.Value) {
        Send "{Esc}"
    }

    ToolTip , 0, 0
    JobTeleportBtn.Value := false
}

DisableAllNet(*) {
    if (DisableAllNetBtn.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=in new enable=yes', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=out new enable=yes', , "hide"
        ToolTip "禁止 所有程序联网", 10, 10
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=in new enable=no', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=out new enable=no', , "hide"
        ToolTip , 10, 10
    }
}
DisableGameNet(*) {
    if (DisableGameNetBtn.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=in new enable=yes', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=out new enable=yes', , "hide"
        ToolTip "禁止 GTA5 联网", 10, 10
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=in new enable=no', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=out new enable=no', , "hide"
        ToolTip , 10, 10
    }
}
DisableGameSave(*) {
    if (DisableGameSaveBtn.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5_SAVING__" dir=out new enable=yes', , "hide"
        ToolTip "禁止 上传线上存档", 10, 10
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5_SAVING__" dir=out new enable=no', , "hide"
        ToolTip , 10, 10
    }
}

LeftMouseClick(*) {
    if !(LeftMouseClickBtn.Value) {
        return
    }

    ToolTip "自动收集财物", 10, 10
    while (true) {
        if !(LeftMouseClickBtn.Value) {
            break
        }

        Send "{Space}"
        Sleep(60)
    }

    ToolTip , 0, 0
    LeftMouseClickBtn.Value := false
}

/*
Test(*) {
    if !(TestBtn.Value) {
        return
    }

    ToolTip "`nTesting`n", 10, 10
    while (true) {
        if !(TestBtn.Value) {
            break
        }
        Sleep(1060)
    }

    ToolTip , 0, 0
    TestBtn.Value := false
}
*/

/* 监听按键 */

F4:: {
    if (JobTeleportBtn.Value) {
        return
    }
    JobTeleportBtn.Value := true
    JobTeleport()
}
^F4:: {
    JobTeleportBtn.Value := false
}

F5:: {
    if (DisableAllNetBtn.Value) {
        return
    }
    DisableAllNetBtn.Value := true
    DisableAllNet()
}
^F5:: {
    if !(DisableAllNetBtn.Value) {
        return
    }
    DisableAllNetBtn.Value := false
    DisableAllNet()
}

F6:: {
    if (DisableGameNetBtn.Value) {
        return
    }
    DisableGameNetBtn.Value := true
    DisableGameNet()
}
^F6:: {
    if !(DisableGameNetBtn.Value) {
        return
    }
    DisableGameNetBtn.Value := false
    DisableGameNet()
}

F7:: {
    if (DisableGameSaveBtn.Value) {
        return
    }
    DisableGameSaveBtn.Value := true
    DisableGameSave()
}
^F7:: {
    if !(DisableGameSaveBtn.Value) {
        return
    }
    DisableGameSaveBtn.Value := false
    DisableGameSave()
}

F8:: {
    if (LeftMouseClickBtn.Value) {
        return
    }
    LeftMouseClickBtn.Value := true
    LeftMouseClick()
}
^F8:: {
    LeftMouseClickBtn.Value := false
}

; Test
/*
F3:: {
    if (TestBtn.Value) {
        TestBtn.Value := false
    } else {
        TestBtn.Value := true
        Test()
    }
}
*/

/* 退出程序 */

MyGui.OnEvent("Close", MyGui_Close)
MyGui_Close(thisGui) {  ; 声明中 this 参数是可选的.
    Result := MsgBox("你确定要退出程序？", "退出", "y/n")
    if (Result = "Yes") {
        AppExit()
    } else {
        return true
    }
}

AppExit() {
    ExitApp
}
