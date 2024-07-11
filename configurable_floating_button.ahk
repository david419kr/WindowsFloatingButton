#Requires AutoHotkey v2.0

configFile := A_ScriptDir . "\config_floating_button.ini"
exePath := ""
transparency := 200
bgColor := "White"
guiW := 100
guiH := 90
aspectRatio := guiW / guiH
mainGuiXY := ""
mainGuiWH := "w" guiW " h" guiH
fontSize := guiW / 10

LoadConfig()

; Main GUI
mainGui := Gui()
mainGui.Opt("+AlwaysOnTop -Caption +ToolWindow +Resize +MinSize100x90")
mainGui.BackColor := bgColor
button := mainGui.Add("Button", "x15 y10 w40 h30", "")
button.OnEvent("Click", RunSelectedExe)
settingsButton := mainGui.Add("Button", "x55 y10 w30 h30", "⚙️")
settingsButton.OnEvent("Click", OpenSettings)
settingsButton.SetFont("s" fontSize)

; Resize GUI
mainGui.OnEvent("Size", GuiResize)

; Settings GUI
settingsGui := Gui("+Owner" . mainGui.Hwnd)
settingsGui.Add("Text", "x10 y10", "Select an exe file:")
exeEdit := settingsGui.Add("Edit", "x10 y30 w250 ReadOnly", exePath)
browseButton := settingsGui.Add("Button", "x270 y28 w70", "Browse")
browseButton.OnEvent("Click", BrowseFile)

settingsGui.Add("Text", "x10 y60", "Opacity:")
transparencySlider := settingsGui.Add("Slider", "x10 y80 w330 Range0-255", transparency)
transparencySlider.OnEvent("Change", UpdateTransparency)

settingsGui.Add("Text", "x10 y110", "Background Color:")
colorChoices := ["White", "Black", "Gray", "Red", "Green", "Blue", "Yellow", "Purple"]
colorDropdown := settingsGui.Add("DropDownList", "x10 y130 w100", colorChoices)
colorDropdown.Choose(1)
colorDropdown.OnEvent("Change", UpdateColorFromDropdown)

settingsGui.Add("Text", "x120 y110", "Can input hex color code manually:")
colorEdit := settingsGui.Add("Edit", "x120 y130 w100", bgColor)
colorEdit.OnEvent("Change", UpdateColorFromEdit)

applyButton := settingsGui.Add("Button", "x290 y160 w70", "Apply")
applyButton.OnEvent("Click", ApplySettings)

exitButton := settingsGui.Add("Button", "x10 y160 w100", "Terminate App")
exitButton.OnEvent("Click", ExitEvent)

; Show main GUI
mainGui.Show(mainGuiXY mainGuiWH)
WinSetTransparent(transparency, mainGui)

OnMessage(0x84, WM_NCHITTEST)
OnMessage(0x83, WM_NCCALCSIZE)

SetTimer checkMousePos, 50

; Drag
OnMessage(0x201, WM_LBUTTONDOWN)
return

ExitEvent(*) {
    SaveGuiPosition()
    SaveConfig()
    ExitApp()
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd != mainGui.Hwnd)
        return

    PostMessage(0xA1, 2, , , "A")
}

RunSelectedExe(*) {
    if (exePath != "")
        Run(exePath)
    else
        MsgBox("Please select an exe file at settings.")
}

OpenSettings(*) {
    settingsGui.Show()
}

BrowseFile(*) {
    global exePath
    exePath := FileSelect("3", , "Select an exe file", "Executable Files (*.exe)")
    if (exePath != "")
        exeEdit.Value := exePath
}

UpdateTransparency(*) {
    global transparency
    transparency := transparencySlider.Value
    WinSetTransparent(transparency, mainGui)
}

UpdateColorFromDropdown(*) {
    global bgColor
    bgColor := colorDropdown.Text
    colorEdit.Value := bgColor
    mainGui.BackColor := bgColor
}

UpdateColorFromEdit(*) {
    global bgColor
    bgColor := colorEdit.Value
    if (IsValidColor(bgColor)) {
        mainGui.BackColor := bgColor
    }
}

IsValidColor(color) {
    return RegExMatch(color, "^[0-9A-Fa-f]{6}$")
}

ApplySettings(*) {
    SaveConfig()
    settingsGui.Hide()
}

LoadConfig() {
    global exePath, transparency, bgColor, mainGuiXY, mainGuiWH, guiW, guiH, aspectRatio, fontSize, configFile
    if (FileExist(configFile)) {
        exePath := IniRead(configFile, "Settings", "ExePath", "")
        transparency := IniRead(configFile, "Settings", "Transparency", 150)
        bgColor := IniRead(configFile, "Settings", "BgColor", "White")
        mainGuiXY := IniRead(configFile, "Position", "mainGuiXY", "")
        guiW := IniRead(configFile, "Settings", "GuiW", 90)
        guiH := IniRead(configFile, "Settings", "GuiH", 40)
        aspectRatio := guiW / guiH
        mainGuiWH := "w" guiW " h" guiH
        fontSize := guiW / 10
    }
}

SaveConfig() {
    global exePath, transparency, bgColor, guiW, guiH, configFile
    IniWrite(exePath, configFile, "Settings", "ExePath")
    IniWrite(transparency, configFile, "Settings", "Transparency")
    IniWrite(bgColor, configFile, "Settings", "BgColor")
    IniWrite(guiW, configFile, "Settings", "GuiW")
    IniWrite(guiH, configFile, "Settings", "GuiH")
}

SaveGuiPosition(*) {
    global mainGui, configFile
    WinGetPos(&x, &y, , , mainGui)
    IniWrite("x" x " y" y " ", configFile, "Position", "mainGuiXY")
}

GuiResize(thisGui, minMax, width, height) {
    global guiW, guiH, aspectRatio, fontSize
    if (minMax = -1)
        return

    newAspectRatio := width / height
    if (newAspectRatio > aspectRatio) {
        width := Round(height * aspectRatio)
    } else if (newAspectRatio < aspectRatio) {
        height := Round(width / aspectRatio)
    }

    guiW := width
    guiH := height

    thisGui.Move(,, width, height)

    buttonBlankW := width * 0.13
    buttonBlankH := height * 0.22
    runButtonW := width * 0.55
    runButtonH := height * 0.6
    settingsButtonW := width * 0.2
    settingsButtonH := height * 0.6
    fontSize := guiW / 10

    button.Move(buttonBlankW, buttonBlankH, runButtonW, runButtonH)
    settingsButton.Move(runButtonW + buttonBlankW, buttonBlankH, settingsButtonW, settingsButtonH)
    settingsButton.SetFont("s" fontSize)

    SaveConfig()
}



; -----Codes below are from AutoHotkey forums-----
; https://www.autohotkey.com/boards/viewtopic.php?t=110389

; Redefine where the sizing borders are.  This is necessary since
; returning 0 for WM_NCCALCSIZE effectively gives borders zero size.
WM_NCHITTEST(wParam, lParam, *){
	static border_size := 6
	if !mainGui
		return
	WinGetPos &gX, &gY, &gW, &gH, mainGui
	x := lParam<<48>>48, y := lParam<<32>>48
	hit_left    := x <  gX+border_size
	hit_right   := x >= gX+gW-border_size
	hit_top     := y <  gY+border_size
	hit_bottom  := y >= gY+gH-border_size
	if hit_top {
		if hit_left
			return 0xD
		else if hit_right
			return 0xE
		else
			return 0xC
	}
	else if hit_bottom{
		if hit_left
			return 0x10
		else if hit_right
			return 0x11
		else
			return 0xF
	}
	else if hit_left
		return 0xA
	else if hit_right
		return 0xB
	
	; else let default hit-testing be done
}

WM_NCCALCSIZE(*){
	return 0
}

checkMousePos(){
	MouseGetPos &CursorX, &CursorY, &Window, &ctl
	if (Window==mainGui.hwnd)
		mainGui.Opt("+0x40000")
	else
		mainGui.Opt("-0x40000")
}
