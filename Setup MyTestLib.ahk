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

DebugMode		:= 1										; Debug mode ON suppresses welcome message and compiled check. You MUST turn DebugMode OFF before compiling for distribution
LibFiles		:= ["MyTestLib.ahk"]						; Which files you wish to add Redirects to in the AHK lib folder

; ======================================================================================


; =========================== MAIN CODE, DO NOT EDIT BELOW =============================

#SingleInstance, force

; Show welcome message. Used in case people running the EXE run this file wondering what it was.
if (!DebugMode){
	msgbox welcome message
}

; Check AHK is installed, and is correct version

; Run named pipe to attempt to pass code to installed AHK interpreter instead of the one this script is running on (because it is compiled)
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
ExitApp

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
		msgbox % "ERROR: This Script has not been compiled.`n`nPlease compile this script before distributing to users."
		ExitApp
	}
}

;LibUnicodeAnsi	:= "A"

Gui, Add, Text, x5 y5 w190 h190 vLog
Gui, Show, W200 H200

/*
if (A_AhkVersion == "1.0.48.05"){
	;msgbox, 4, Title, % "WARNING.`nYou are using a version of AutoHotkey from Autohotkey.com!`nThis version is no longer supported and is out of date.`nPlease use the version from ahkscript.org instead.`n`nDo you wish to open a browser window to that site now?"
	IfMsgBox Yes
		Run http://ahkscript.org
	;ExitApp
}
*/

;LibFiles = []
AHKFolder := Substr(A_AhkPath,1,Instr(A_AhkPath,"\",false,0))
LibFolder := AHKFolder "Lib"

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

Loop % LibFiles.MaxIndex() {
	; Check source file exists
	if (FileExist(ScriptFolder LibFiles[A_Index])){
		;msgbox local copy found
	}

	; Check for conflicts
	if (FileExist(LibFolder LibFiles[A_Index])){
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
					AddToLog(LibFiles[A_Index] ": Redirect FAILED`n")
					continue
				}
			} else {
				AddToLog(LibFiles[A_Index] ": Redirect FAILED`n")
				continue
			}
		} else {
			; One line of text, possibly a redirect.
			msgbox, 4, Replace Code?, % "There is already a file at the following location:" LibFolder LibFiles[A_Index] "`nIt appears to be an old Redirect File, as it is only one line.`n`nIs it OK to replace it?"
			IfMsgBox, Yes 
			{
				FileDelete, % LibFolder LibFiles[A_Index]
				if (ErrorLevel != 0){
					msgbox % "Could not delete " LibFolder LibFiles[A_Index]
					AddToLog(LibFiles[A_Index] ": Redirect FAILED`n")
					continue
				}
			} else {
				AddToLog(LibFiles[A_Index] ": Redirect FAILED`n")
				continue
			}
		}
	}

	; Create the include
	CreateRedirect(A_Index)
	if (ErrorLevel == 0){
		AddToLog(LibFiles[A_Index] ": Redirected OK`n")
	} else {
		msgbox % "Could not create Redirect File "LibFolder LibFiles[A_Index]
		AddToLog(LibFiles[A_Index] ": Redirect FAILED`n")
	}

}

Return

CreateRedirect(idx){
	global ScriptFolder, LibFolder, LibFiles
	FileAppend , % "#include " ScriptFolder LibFiles[idx], % LibFolder LibFiles[idx]
}

AddToLog(text){
	global Log
	Log .= text
	GuiControl, , Log , % Log	
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
	/*
	file := A_ScriptDir "\DynaRun.txt"
	version := 0

	ret := dynarun("FileAppend % A_AhkVersion, " file, "pipename")
	if (ret){
		sleep 20 ; give the script some time to finish
		while !FileExist(file)
			continue
		FileRead version, % file
		FileDelete % file
		return version
	} else {
		; Could not get AHK version
		;msgbox % "AHK not installed"
		return 0
	}
	*/

}

/*
DynaRun(TempScript, name="") {
   static _:="uint",@:="Ptr"
   __PIPE_GA_ := DllCall("CreateNamedPipe","str","\\.\pipe\" name,_,2,_,0,_,255,_,0,_,0,@,0,@,0)
   __PIPE_    := DllCall("CreateNamedPipe","str","\\.\pipe\" name,_,2,_,0,_,255,_,0,_,0,@,0,@,0)
   if (__PIPE_=-1 or __PIPE_GA_=-1)
      Return 0
   Run, %A_AhkPath% "\\.\pipe\%name%",,UseErrorLevel HIDE, PID
   If ErrorLevel
      Return 0
      ;MsgBox, 262144, ERROR,% "Could not open file:`n" __AHK_EXE_ """\\.\pipe\" name """"
   DllCall("ConnectNamedPipe",@,__PIPE_GA_,@,0)
   DllCall("CloseHandle",@,__PIPE_GA_)
   DllCall("ConnectNamedPipe",@,__PIPE_,@,0)
   script := (A_IsUnicode ? chr(0xfeff) : (chr(239) . chr(187) . chr(191))) TempScript
   if !DllCall("WriteFile",@,__PIPE_,"str",script,_,(StrLen(script)+1)*(A_IsUnicode ? 2 : 1),_ "*",0,@,0)
      Return A_LastError,DllCall("CloseHandle",@,__PIPE_)
   DllCall("CloseHandle",@,__PIPE_)
   Return PID
}
*/
GuiClose:
	ExitApp
