/*
ToDo:
* Check 32/64-bit AHK / OS?
* Check A_IsCompiled?

*/

#SingleInstance, force
LibFiles		:= ["MyTestLib.ahk"]
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

GuiClose:
	ExitApp
