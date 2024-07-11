#Requires AutoHotkey v2.0

global mainGuiHwnd := 0
scriptName := StrSplit(A_ScriptName, ".")[1]
configFile := A_ScriptDir . "\" . scriptName . "_config.ini"
exePath := ""
transparency := 200
bgColor := "White"
guiW := 100
guiH := 90
aspectRatio := guiW / guiH
mainGuiXY := ""
mainGuiWH := "w" guiW " h" guiH
fontSize := guiW / 10
iconSize := guiW / 2.5

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
mainGuiHwnd := mainGui.Hwnd

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
    global exePath, button
    exePath := FileSelect("3", , "Select an exe file", "Executable Files (*.exe)")
    if (exePath != "") {
        exeEdit.Value := exePath
        GuiButtonIcon(button.Hwnd, exePath, 0, "s" iconSize)
    }
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
    global guiW, guiH, aspectRatio, fontSize, iconSize
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
    iconSize := guiW / 2.5

    button.Move(buttonBlankW, buttonBlankH, runButtonW, runButtonH)
    GuiButtonIcon(button.Hwnd, exePath, 0, "s" iconSize)
    settingsButton.Move(runButtonW + buttonBlankW, buttonBlankH, settingsButtonW, settingsButtonH)
    settingsButton.SetFont("s" fontSize)

    SaveConfig()
}

; -----Codes below are from AutoHotkey forums-----
; https://www.autohotkey.com/boards/viewtopic.php?t=110389
; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=115871

; Redefine where the sizing borders are.  This is necessary since
; returning 0 for WM_NCCALCSIZE effectively gives borders zero size.
WM_NCHITTEST(wParam, lParam, msg, hwnd){
	static border_size := 6
    if !mainGui || hwnd != mainGui.Hwnd
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

WM_NCCALCSIZE(wParam, lParam, msg, hwnd) {
    if hwnd == mainGuiHwnd
        return 0
    ; else let default processing be done
}

checkMousePos(){
	MouseGetPos &CursorX, &CursorY, &Window, &ctl
	if (Window==mainGui.hwnd)
		mainGui.Opt("+0x40000")
	else
		mainGui.Opt("-0x40000")
}

;{ [Function] GuiButtonIcon
;{
; Fanatic Guru
; Version 2023 04 08
;
; #Requires AutoHotkey v2.0.2+
;
; FUNCTION to Assign an Icon to a Gui Button
;
;------------------------------------------------
;
; Method:
;   GuiButtonIcon(Handle, File, Index, Options)
;
;   Parameters:
;   1) {Handle} 	HWND handle of Gui button or the Gui button object
;   2) {File} 		File containing icon image
;   3) {Index} 		Index of icon in file
;						Optional: Default = 1
;   4) {Options}	Single letter flag followed by a number with multiple options delimited by a space
;						W = Width of Icon (default = 16)
;						H = Height of Icon (default = 16)
;						S = Size of Icon, Makes Width and Height both equal to Size
;						L = Left Margin
;						T = Top Margin
;						R = Right Margin
;						B = Botton Margin
;						A = Alignment (0 = left, 1 = right, 2 = top, 3 = bottom, 4 = center; default = 4)
;
; Return:
;   1 = icon found, 0 = icon not found
;
; Example:
; MyGui := Gui()
; MyButton := MyGui.Add('Button', 'w70 h38', 'Save')
; GuiButtonIcon(MyButton, 'shell32.dll', 259, 's32 a1 r2')
; MyGui.Show
;}
GuiButtonIcon(Handle, File, Index := 1, Options := '')
{
	RegExMatch(Options, 'i)w\K\d+', &W) ? W := W.0 : W := 16
	RegExMatch(Options, 'i)h\K\d+', &H) ? H := H.0 : H := 16
	RegExMatch(Options, 'i)s\K\d+', &S) ? W := H := S.0 : ''
	RegExMatch(Options, 'i)l\K\d+', &L) ? L := L.0 : L := 0
	RegExMatch(Options, 'i)t\K\d+', &T) ? T := T.0 : T := 0
	RegExMatch(Options, 'i)r\K\d+', &R) ? R := R.0 : R := 0
	RegExMatch(Options, 'i)b\K\d+', &B) ? B := B.0 : B := 0
	RegExMatch(Options, 'i)a\K\d+', &A) ? A := A.0 : A := 4
	W *= A_ScreenDPI / 96, H *= A_ScreenDPI / 96
	button_il := Buffer(20 + A_PtrSize)
	normal_il := DllCall('ImageList_Create', 'Int', W, 'Int', H, 'UInt', 0x21, 'Int', 1, 'Int', 1)
	NumPut('Ptr', normal_il, button_il, 0)			; Width & Height
	NumPut('UInt', L, button_il, 0 + A_PtrSize)		; Left Margin
	NumPut('UInt', T, button_il, 4 + A_PtrSize)		; Top Margin
	NumPut('UInt', R, button_il, 8 + A_PtrSize)		; Right Margin
	NumPut('UInt', B, button_il, 12 + A_PtrSize)	; Bottom Margin
	NumPut('UInt', A, button_il, 16 + A_PtrSize)	; Alignment
	SendMessage(BCM_SETIMAGELIST := 5634, 0, button_il, Handle)
	Return IL_Add(normal_il, File, Index)
}
;}