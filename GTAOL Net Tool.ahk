/************************************************************************
 * @description GTAOL Net Tool
 * @author Rostal
 * @date 2024/12/12
 * @version 1.2
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance
#UseHook

TITLE := "GTAOL Net Tool"
GTA_TITLE := "Grand Theft Auto"
WLAN_INTERFACE := "WLAN"

if not A_IsAdmin {
    MsgBox("你需要以管理员身份运行该程序", TITLE, "OK")
    ExitApp
}

/* 定义热键 */

HK_AFK := "F3"
HK_JOB_TELEPORT := "F4"
HK_BLOCK_ALL_NET := "F5"
HK_BLOCK_GAME_NET := "F6"
HK_BLOCK_GAME_SAVE := "F7"
HK_DISABLE_WIFI := "F8"

/* --------------------------------
        创建 GUI 控件
-------------------------------- */

MyGui := Gui(, TITLE)
MyGui.Opt("+Resize")

MyGui.Add("Text", , "先添加防火墙规则，否则功能无效")

MyGui.Add("Button", "h32 Section", "添加防火墙规则").OnEvent("Click", AddFireWallRules)

MyGui.Add("Button", "hp x+m ", "删除防火墙规则").OnEvent("Click", DelFireWallRules)

MyGui.Add("Button", "hp x+m ", "打开防火墙规则设置").OnEvent("Click", OpenFireWallRules)

/* 快捷键功能 */

MyGui.Add("Text", "xs y+24 Section w320", "快捷键功能").SetFont("bold")
MyGui.Add("Text", "x+m ys wp", "禁用快捷键").SetFont("bold")

toggleAfk := MyGui.Add("Checkbox", "xs y+16 w320", "[" HK_AFK "]  挂机（每秒按一次 K 键）")
toggleAfk.OnEvent("Click", Afk)
toggleAfk_HK := MyGui.Add("Checkbox", "x+m+16 wp", "")
toggleAfk_HK.OnEvent("Click", Afk_HK)

toggleJobTeleport := MyGui.Add("Checkbox", "xs y+16 wp", "[" HK_JOB_TELEPORT "]  模拟 Alt + F4 差传（等待40s后返回）")
toggleJobTeleport.OnEvent("Click", JobTeleport)
toggleJobTeleport_HK := MyGui.Add("Checkbox", "x+m+16 wp", "")
toggleJobTeleport_HK.OnEvent("Click", JobTeleport_HK)

toggleBlockAllNet := MyGui.Add("Checkbox", "xs y+16 wp", "[" HK_BLOCK_ALL_NET "]  禁止 所有程序联网")
toggleBlockAllNet.OnEvent("Click", BlockAllNet)
toggleBlockAllNet_HK := MyGui.Add("Checkbox", "x+m+16 wp", "")
toggleBlockAllNet_HK.OnEvent("Click", BlockAllNet_HK)

toggleBlockGameNet := MyGui.Add("Checkbox", "xs y+16 wp", "[" HK_BLOCK_GAME_NET "]  禁止 GTA5 联网")
toggleBlockGameNet.OnEvent("Click", BlockGameNet)
toggleBlockGameNet_HK := MyGui.Add("Checkbox", "x+m+16 wp", "")
toggleBlockGameNet_HK.OnEvent("Click", BlockGameNet_HK)

toggleBlockGameSave := MyGui.Add("Checkbox", "xs y+16 wp", "[" HK_BLOCK_GAME_SAVE "]  禁止 上传线上存档")
toggleBlockGameSave.OnEvent("Click", BlockGameSave)
toggleBlockGameSave_HK := MyGui.Add("Checkbox", "x+m+16 wp", "")
toggleBlockGameSave_HK.OnEvent("Click", BlockGameSave_HK)

toggleDisableWiFi := MyGui.Add("Checkbox", "xs y+16 wp", "[" HK_DISABLE_WIFI "]  禁用 WiFi 网络适配器")
toggleDisableWiFi.OnEvent("Click", DisableWiFi)
toggleDisableWiFi_HK := MyGui.Add("Checkbox", "x+m+16 wp", "")
toggleDisableWiFi_HK.OnEvent("Click", DisableWiFi_HK)

btnWiFiName := MyGui.Add("Button", "xs y+16", "WiFi 网络适配器名称")
btnWiFiName.OnEvent("Click", WiFiName)

btnShowInterface := MyGui.Add("Button", "x+m", "查看网络适配器")
btnShowInterface.OnEvent("Click", ShowInterface)

/* 说明 */

MyGui.Add("Text", "xs y+32 wp", "说明").SetFont("bold")

MyGui.Add("Text", "xs y+16", "1. 如果使用了加速器或者其它代理工具，防火墙规则可能会无效")
MyGui.Add("Text", "xs y+m", "2. 挂机和模拟差传可能需要手动点击开关来关闭功能")

/* 显示窗口 */

MyGui.Show("w480 h600 Center")

/* --------------------------------
        基础
-------------------------------- */

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

; 启用/禁用热键
ToggleHotkey(keyName, toggle) {
    if toggle {
        toggle := "Off"
    } else {
        toggle := "On"
    }
    Hotkey keyName, toggle
}

/* --------------------------------
        GUI 控件 绑定事件
-------------------------------- */

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
    if (toggleAfk.Value) {
        SetTimer Afk_Timer, 1000
    } else {
        SetTimer Afk_Timer, 0
    }
    ShowStatusText("挂机（每秒按一次 K 键）", toggleAfk.Value)
}
Afk_HK(*) {
    ToggleHotkey(HK_AFK, toggleAfk_HK.Value)
}

PressAltF4() {
    if WinExist(GTA_TITLE) {
        PostMessage 0x112, 0xF060, , , GTA_TITLE ; 0x112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
    }
}
JobTeleport(*) {
    if !(toggleJobTeleport.Value) {
        return
    }

    PressAltF4()

    floatingTextGui.Show("xCenter y 10 NoActivate")

    /* 等待 40s */
    index := 40
    while (index > 0) {
        if !(toggleJobTeleport.Value) {
            break
        }

        floatingText.Text := "剩余时间: " index "s", 10, 10
        Sleep(1000)
        index -= 1
    }

    if (toggleJobTeleport.Value) {
        Send "{Esc}"
    }

    toggleJobTeleport.Value := false
    floatingTextGui.Hide()
}
JobTeleport_HK(*) {
    ToggleHotkey(HK_JOB_TELEPORT, toggleJobTeleport_HK.Value)
}

BlockAllNet(*) {
    if (toggleBlockAllNet.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=in new enable=yes', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=out new enable=yes', , "hide"
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=in new enable=no', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_ALL__" dir=out new enable=no', , "hide"
    }
    ShowStatusText("禁止 所有程序联网", toggleBlockAllNet.Value)
}
BlockAllNet_HK(*) {
    ToggleHotkey(HK_BLOCK_ALL_NET, toggleBlockAllNet_HK.Value)
}

BlockGameNet(*) {
    if (toggleBlockGameNet.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=in new enable=yes', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=out new enable=yes', , "hide"
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=in new enable=no', , "hide"
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5__" dir=out new enable=no', , "hide"
    }
    ShowStatusText("禁止 GTA5 联网", toggleBlockGameNet.Value)
}
BlockGameNet_HK(*) {
    ToggleHotkey(HK_BLOCK_GAME_NET, toggleBlockGameNet_HK.Value)
}

BlockGameSave(*) {
    if (toggleBlockGameSave.Value) {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5_SAVING__" dir=out new enable=yes', , "hide"
    } else {
        RunWait 'netsh advfirewall firewall set rule name="__BLOCK_GTA5_SAVING__" dir=out new enable=no', , "hide"
    }
    ShowStatusText("禁止 上传线上存档", toggleBlockGameSave.Value)
}
BlockGameSave_HK(*) {
    ToggleHotkey(HK_BLOCK_GAME_SAVE, toggleBlockGameSave_HK.Value)
}

DisableWiFi(*) {
    if (toggleDisableWiFi.Value) {
        RunWait 'netsh interface set interface "' WLAN_INTERFACE '" disabled', , "hide"
    } else {
        RunWait 'netsh interface set interface "' WLAN_INTERFACE '" enabled', , "hide"
    }
    ShowStatusText("禁用 WiFi 网络适配器", toggleDisableWiFi.Value)
}
DisableWiFi_HK(*) {
    ToggleHotkey(HK_DISABLE_WIFI, toggleDisableWiFi_HK.Value)
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

/* --------------------------------
        绑定热键事件
-------------------------------- */

Hotkey HK_AFK, Afk_HKEvent
Afk_HKEvent(*) {
    toggleAfk.Value := !toggleAfk.Value
    Afk()
}

Hotkey HK_JOB_TELEPORT, JobTeleport_HKEvent
JobTeleport_HKEvent(*) {
    toggleJobTeleport.Value := !toggleJobTeleport.Value
    JobTeleport()
}

Hotkey HK_BLOCK_ALL_NET, BlockAllNet_HKEvent
BlockAllNet_HKEvent(*) {
    toggleBlockAllNet.Value := !toggleBlockAllNet.Value
    BlockAllNet()
}

Hotkey HK_BLOCK_GAME_NET, BlockGameNet_HKEvent
BlockGameNet_HKEvent(*) {
    toggleBlockGameNet.Value := !toggleBlockGameNet.Value
    BlockGameNet()
}

Hotkey HK_BLOCK_GAME_SAVE, BlockGameSave_HKEvent
BlockGameSave_HKEvent(*) {
    toggleBlockGameSave.Value := !toggleBlockGameSave.Value
    BlockGameSave()
}

Hotkey HK_DISABLE_WIFI, DisableWiFi_HKEvent
DisableWiFi_HKEvent(*) {
    toggleDisableWiFi.Value := !toggleDisableWiFi.Value
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
