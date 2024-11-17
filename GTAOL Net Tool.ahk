/************************************************************************
 * @description GTAOL Net Tool
 * @author Rostal
 * @date 2024/11/17
 * @version 1.1
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance

TITLE := "GTAOL Net Tool"
GTA_TITLE := "Grand Theft Auto"
WLAN_INTERFACE := "WLAN"

if not A_IsAdmin {
    MsgBox("你需要以管理员身份运行该程序", TITLE, "OK")
    ExitApp
}

MyGui := Gui(, TITLE)
MyGui.Opt("+Resize")

/* 创建 GUI 控件 */

MyGui.Add("Text", , "先添加防火墙规则，否则功能无效")

MyGui.Add("Button", "h32 Section", "添加防火墙规则").OnEvent("Click", AddFireWallRules)

MyGui.Add("Button", "hp x+m ", "删除防火墙规则").OnEvent("Click", DelFireWallRules)

MyGui.Add("Button", "hp x+m ", "打开防火墙规则设置").OnEvent("Click", OpenFireWallRules)

MyGui.Add("Text", "xs y+24 Section w320", "快捷键功能（Ctrl + 快捷键 为关闭功能）").SetFont("bold")

AfkBtn := MyGui.Add("Checkbox", "xs y+16 w320", "[F3]  挂机（每秒按一次 K 键）")
AfkBtn.OnEvent("Click", Afk)

JobTeleportBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F4]  模拟 Alt + F4 差传（等待40s后返回）")
JobTeleportBtn.OnEvent("Click", JobTeleport)

DisableAllNetBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F5]  禁止 所有程序联网")
DisableAllNetBtn.OnEvent("Click", DisableAllNet)

DisableGameNetBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F6]  禁止 GTA5 联网")
DisableGameNetBtn.OnEvent("Click", DisableGameNet)

DisableGameSaveBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F7]  禁止 上传线上存档")
DisableGameSaveBtn.OnEvent("Click", DisableGameSave)

DisableWiFiBtn := MyGui.Add("Checkbox", "xs y+16 wp", "[F8]  禁用 WiFi 网络适配器")
DisableWiFiBtn.OnEvent("Click", DisableWiFi)

WiFiNameBtn := MyGui.Add("Button", "xs y+16", "WiFi 网络适配器名称")
WiFiNameBtn.OnEvent("Click", WiFiName)

ShowInterfaceBtn := MyGui.Add("Button", "x+m", "查看网络适配器")
ShowInterfaceBtn.OnEvent("Click", ShowInterface)

MyGui.Add("Text", "xs y+32 wp", "说明").SetFont("bold")

MyGui.Add("Text", "xs y+16", "1. 如果使用了加速器或者其它代理工具，防火墙规则可能会无效")
MyGui.Add("Text", "xs y+m", "2. 开启挂机后需要手动点开关来关闭")

/* 显示窗口 */

MyGui.Show("w480 h600 Center")

/* 基础 */

Thread "Interrupt", 0  ; 使所有线程始终处于可中断状态.
CoordMode "ToolTip"

; 提示信息
statusText := ""
ShowStatusText(text, toggle) {
    global statusText

    if toggle {
        if StrLen(statusText) > 0 {
            statusText := statusText "`n"
        }
        statusText := statusText text
    } else {
        statusText := StrReplace(statusText, text)
        statusText := Trim(statusText, "`n")
    }

    ToolTip statusText, 10, 10
}

; 临时提示文本
floatingTextGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
floatingTextGui.BackColor := "000000"
floatingTextGui.SetFont("cFFFFFF s15")
floatingText := floatingTextGui.Add("Text", , "剩余时间: 40s")

/* GUI 控件 绑定事件 */

GetGamePath() {
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

AddFireWallRules(*) {
    cmdStart := 'netsh advfirewall firewall add rule '
    cmdEnd1 := ' dir=in action=block enable=no'
    cmdEnd2 := ' dir=out action=block enable=no'

    RunWait cmdStart 'name="__BLOCK_ALL__"' cmdEnd1, , "hide"
    RunWait cmdStart 'name="__BLOCK_ALL__"' cmdEnd2, , "hide"

    GamePath := GetGamePath()
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
DelFireWallRules(*) {
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
OpenFireWallRules(*) {
    RunWait "wf.msc", , "hide"
}

Afk_Timer() {
    Send "{K}"
}
Afk(*) {
    if (AfkBtn.Value) {
        SetTimer Afk_Timer, 1000
    } else {
        SetTimer Afk_Timer, 0
    }
    ShowStatusText("挂机（每秒按一次 K 键）", AfkBtn.Value)
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

    floatingTextGui.Show("xCenter y 10 NoActivate")

    /* 等待 40s */
    index := 40
    while (index > 0) {
        if !(JobTeleportBtn.Value) {
            break
        }

        floatingText.Text := "剩余时间: " index "s", 10, 10
        Sleep(1000)
        index -= 1
    }

    if (JobTeleportBtn.Value) {
        Send "{Esc}"
    }

    JobTeleportBtn.Value := false
    floatingTextGui.Hide()
}

DisableAllNet(*) {
    if (DisableAllNetBtn.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=in new enable=yes', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=out new enable=yes', , "hide"
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=in new enable=no', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=out new enable=no', , "hide"
    }
    ShowStatusText("禁止 所有程序联网", DisableAllNetBtn.Value)
}
DisableGameNet(*) {
    if (DisableGameNetBtn.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=in new enable=yes', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=out new enable=yes', , "hide"
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=in new enable=no', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=out new enable=no', , "hide"
    }
    ShowStatusText("禁止 GTA5 联网", DisableGameNetBtn.Value)
}
DisableGameSave(*) {
    if (DisableGameSaveBtn.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5_SAVING__" dir=out new enable=yes', , "hide"
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5_SAVING__" dir=out new enable=no', , "hide"
    }
    ShowStatusText("禁止 上传线上存档", DisableGameSaveBtn.Value)
}

DisableWiFi(*) {
    if (DisableWiFiBtn.Value) {
        RunWait 'netsh interface set interface "' WLAN_INTERFACE '" disabled', , "hide"
    } else {
        RunWait 'netsh interface set interface "' WLAN_INTERFACE '" enabled', , "hide"
    }
    ShowStatusText("禁用 WiFi 网络适配器", DisableWiFiBtn.Value)
}
WiFiName(*) {
    global WLAN_INTERFACE

    IB := InputBox(, "WiFi 网络适配器名称", "h80", WLAN_INTERFACE)
    if (IB.Result = "OK") {
        WLAN_INTERFACE := IB.Value
    }
}
ShowInterface(*) {
    RunWait "ncpa.cpl", , "hide"
}

/* 监听按键 */

F3:: {
    if (AfkBtn.Value) {
        return
    }
    AfkBtn.Value := true
    Afk()
}
^F3:: {
    if !(AfkBtn.Value) {
        return
    }
    AfkBtn.Value := false
    Afk()
}

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
    if (DisableWiFiBtn.Value) {
        return
    }
    DisableWiFiBtn.Value := true
    DisableWiFi()
}
^F8:: {
    if !(DisableWiFiBtn.Value) {
        return
    }
    DisableWiFiBtn.Value := false
    DisableWiFi()
}

/* 退出程序 */

MyGui.OnEvent("Close", MyGui_Close)
MyGui_Close(*) {
    Result := MsgBox("你确定要退出程序？", "退出", "y/n")
    if (Result = "Yes") {
        AppExit()
    } else {
        return true
    }
}

AppExit() {
    ExitApp()
}
