/*
AHK-Library-Setup

ABOUT
=====

A "Setup" system for AHK library writers to ensure the machines of people using their library are set up correctly to use it.

It performs the following primary functions:

* Places a "Redirect" .ahk file in the AutoHotkey lib that points to the library.
This allows any ahk file to #include <library name>, whilst letting the actual source of the library remain outside the AHK Lib folder (Say in a GitHub repo folder)

* Checks that AutoHotkey is installed.

* Checks that AHK is not an old version from AutoHotkey.com

USAGE
=====

Rename the script appropriately, eg "Setup AutoHotkey for MyNewLib.ahk"
Edit the variables in the DEVELOPER SETTINGS section.
While testing for release, you may keep DebugMode on 1

When releasing, set DebugMode to 0, then COMPILE this script (Right click, Compile to EXE)
You do not need to bundle the ahk file with the Library.

*/

; ========================== DEVELOPER SETTINGS ========================================

; Debug mode ON suppresses welcome message and compiled check. You MUST turn DebugMode OFF before compiling for distribution
DebugMode		:= 0

LibName			:= "My Test Library"

; Which files you wish to add Redirects to in the AHK lib folder
LibFiles		:= ["MyTestLib.ahk"]

; Size of the Setup Window [x,y]. You can omit Y (or set it to 0) and the GUI will Auto-Size.
WindowSize		:= [300,0]

; If you want to leave some instructions to users, put text in this var and it will appear in the DEVELOPER NOTES section.
; This section may not appear if the UI is too small.
; If you want a lot of text, you will have to manually set WindowSize[2].
DevNotes		:= "Put your own text here.`n`nYou can use links, eg <a href=""http://evilc.com"">evilC.com</a>"

; What the main include file is.
; This is mainly used when generating usage examples for users.
MainInclude		:= "MyTestLib"									

; ======================================================================================


; =========================== MAIN CODE, DO NOT EDIT BELOW =============================

; Ensure Running as Admin to give max chance file operations will work.
RunAsAdmin()

/*
ToDo:
* Unicode / Ansi check?
*/

AHKFolder := Substr(A_AhkPath,1,Instr(A_AhkPath,"\",false,0))
LibFolder := AHKFolder "Lib"

#SingleInstance, force

; Show welcome message. Used in case people running the EXE run this file wondering what it was.
if (!DebugMode){
	msgbox, 1, Welcome, % "Welcome to the Setup application for " LibName ".`n`nThis application is for coders who wish to use '" LibName "' in their coding projects.`nIf you are not a coder, and a little confused right now, just hit Cancel.`n`nIf you do want to use this library in your projects, this app will help you set up AHK so you can easily include this library from any folder on your computer using the following syntax:`n`n#include <" MainInclude ">`n`nNote that there is no .ahk extension!`n#include <" MainInclude ">, not #include <" MainInclude ".ahk>"
	IfMsgBox, Cancel
		ExitApp
}

; Check AHK is installed, and is correct version
version := DetectInstalledAHKVersion()
if (version){
	if (version <= "1.0.48.05"){
		msgbox, 4, Error, % "WARNING.`nYou are using a version of AutoHotkey from Autohotkey.com!`nThis version is no longer supported and is out of date.`nPlease use the version from ahkscript.org instead.`n`nDo you wish to open a browser window to that site now?"
		IfMsgBox Yes
			Run http://ahkscript.org
		ExitApp
	}
	;msgbox % "Installed version: " version
} else {
	; Could not get AHK version
	msgbox, 4, Error, % "AutoHotkey does not appear to be installed.`n`nWould you like to go to the AutoHotkey website now?"
}

; Check Developer packaged Setup OK
if (A_IsCompiled){
	if (DebugMode){
		msgbox % "ERROR: Developer compiled with DebugMode ON.`n`nPlease turn off DebugMode and re-compile before distributing to users."
		ExitApp
	}
	if (A_PtrSize == 8){
		msgbox % "ERROR: Developer compiled using 64-bit AutoHotkey - 32-bit users will not be able to run Setup.`n`nPlease re-compile using 32-bit Autohotkey."
		ExitApp
	}
} else {
	if (!DebugMode){
		msgbox % "ERROR: This Script has not been compiled.`n`nPlease compile this script before distributing to users.`n`nIf you are not a developer or do not know what the this file is, you can ignore or delete it."
		ExitApp
	}
}

LINE_SIZE := 24
FULL_WIDTH := WindowSize[1] - 10
HEADER_SIZE := 10

Gui, Add, Text, % "x5 y10 w" WindowSize[1]-10 " center", Files to be Installed for this Library
Loop % LibFiles.MaxIndex() {
	line_y := HEADER_SIZE + (A_Index * (LINE_SIZE - 1))
	Gui, Add, Text, % "x5 y" line_y " w100", % LibFiles[A_Index]
	Gui, Add, Text, % "x" WindowSize[1] - 105 " y" line_y " w100 center vRedirectResult" A_Index, PENDING
}
Gui, Add, GroupBox, % "x0 y0 w" WindowSize[1] - 4 " h" HEADER_SIZE + (LINE_SIZE - 5) + (LibFiles.Maxindex() * LINE_SIZE)

main_bottom := (LibFiles.MaxIndex() * LINE_SIZE) + 10 + LINE_SIZE

; Done main bit of Gui, now need to know window height (if previously specified)
if (!WindowSize[2]){
	; Window Height not specified - work out how much more space we need.
	if (DevNotes){
		WindowSize[2] := main_bottom + 100
	} else {
		WindowSize[2] := main_bottom + 20
	}
}

; Work out where we put the Ok button
ok_top := WindowSize[2] - 25

; How much space do we have left?
remain_space := ok_top - main_bottom

Gui, Add, Button, % "x" (WindowSize[1] / 2 ) - 25 " y" (WindowSize[2] - 25) " w50 gInstall", Install

; If we have 20 or  more pixels free between the bottom of the install list and the ok button, show dev notes.
if (remain_space > 30 && DevNotes != ""){
	Gui, Add, Text, % "x5 y" main_bottom " w" FULL_WIDTH " center", DEVELOPER NOTES
	Gui, Add, Link, % "x5 y" main_bottom + 20 " w" FULL_WIDTH " h" remain_space - 20, % DevNotes
	box_top := main_bottom - 10
	Gui, Add, GroupBox, % "x0 y" box_top " w" WindowSize[1] - 4 " h" ok_top - box_top - 5
}

Gui, Show, % "W" WindowSize[1] " H" WindowSize[2]
Return

; Perform the Install
Install:
	If (!FileExist(AHKFolder)){
		msgbox % "The AHK folder (" AHKFolder ") Does not seem to exist. Exiting."
	}
	If (!FileExist(LibFolder)){
		msgbox, 4, Lib Folder Missing, % "The AHK Lib folder (" AHKFolder "Lib) Does not seem to exist.`n`nIs it OK to create it?"
		IfMsgBox Yes
			FileCreateDir, % LibFolder
			if (ErrorLevel != 0){
				msgbox % "Could not create " LibFolder "`n`nExiting."
				ExitApp
			}
		Else
			ExitApp
	}

	LibFolder .= "\"
	ScriptFolder := A_ScriptDir "\"

	succeeded := 0
	Loop % LibFiles.MaxIndex() {
		failed := 0
		; Check source file exists
		if (FileExist(ScriptFolder LibFiles[A_Index])){
			;msgbox local copy found
		} else {
			msgbox % ScriptFolder LibFiles[A_Index] " Does not exist."
			failed := 1
		}

		; Check for conflicts
		if (!failed && FileExist(LibFolder LibFiles[A_Index])){
			; Lib file found in lib folder
			; Is it code or an old redirect?
			count := 0
			Loop, Read, % LibFolder LibFiles[A_Index]
			{
				If (trim(A_LoopReadLine) != ""){
					count++
				}
			}
			if (count > 1){
				; More than one line of text. Not a redirect.
				msgbox, 4, Replace Code?, % "There is already a file at the following location:" LibFolder LibFiles[A_Index] "`nIt appears to be code, not a Redirect File, as it is more than one line.`n`nIs it OK to replace it?"
				IfMsgBox, Yes 
				{
					FileDelete, % LibFolder LibFiles[A_Index]
					if (ErrorLevel != 0){
						msgbox % "Could not delete " LibFolder LibFiles[A_Index]
						failed := 1
					}
				} else {
					failed := 1
				}
			} else {
				; One line of text, possibly a redirect.
				msgbox, 4, Replace Code?, % "There is already a file at the following location:" LibFolder LibFiles[A_Index] "`nIt appears to be an old Redirect File, as it is only one line.`n`nIs it OK to replace it?"
				IfMsgBox, Yes 
				{
					FileDelete, % LibFolder LibFiles[A_Index]
					if (ErrorLevel != 0){
						msgbox % "Could not delete " LibFolder LibFiles[A_Index]
						falied := 1
					}
				} else {
					failed := 1
				}
			}
		}

		if (!failed){
			; As long as we did not fail previously...

			; Create the include
			CreateRedirect(A_Index)
			if (ErrorLevel == 0){
				succeeded++
			} else {
				msgbox % "Could not create Redirect File "LibFolder LibFiles[A_Index]
				failed := 1
			}
		}

		; Update the UI
		if (failed){
			GuiControl, , % "RedirectResult" A_Index , FAILED
		} else {
			GuiControl, , % "RedirectResult" A_Index, SUCCEEDED
		}

		if (succeeded == LibFiles.MaxIndex()){
			; All files installed OK
			msgbox, 4, Setup Complete, % "All Libraries Set Up OK.`nYou may now include this library in your projects using the following syntax:`n`n#include <" MainInclude ">`n`nDo you wish to copy this text to the clipboard now?"
			IfMsgBox, Yes
				Clipboard := "#include <" MainInclude ">"
		} else {
			; All files not installed OK
			msgbox % "Some or all of the Set Up procedure failed. The library may not work."
		}

	}

	Return

CreateRedirect(idx){
	global ScriptFolder, LibFolder, LibFiles
	FileAppend , % "#include " ScriptFolder LibFiles[idx], % LibFolder LibFiles[idx]
}

; Detects which version of AHK is installed.
; Returns 0 if not installed
; Note that we CANNOT use A_AhkVersion, as this script is going to be compiled, so that would return the version it was compiled with.
DetectInstalledAHKVersion(){
	RegRead, reg, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoHotkey, DisplayVersion
	if (reg){
		return reg
	} else {
		return 0
	}
}

; Run as admin code from http://www.autohotkey.com/board/topic/46526-
RunAsAdmin(){
	Global 0
	IfEqual, A_IsAdmin, 1, Return 0
	Loop, %0% {
		params .= A_Space . %A_Index%
	}
	DllCall("shell32\ShellExecute" (A_IsUnicode ? "":"A"),uint,0,str,"RunAs",str,(A_IsCompiled ? A_ScriptFullPath
		: A_AhkPath),str,(A_IsCompiled ? "": """" . A_ScriptFullPath . """" . A_Space) params,str,A_WorkingDir,int,1)
	ExitApp
}

GuiClose:
	ExitApp
