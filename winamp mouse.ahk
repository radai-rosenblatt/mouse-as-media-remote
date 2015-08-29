; this script allows control over winamp (and to a lesser degree most media players) using the mouse
; the mouse can be toggled between normal operation mode and "remote" mode by holding down the middle
; mouse button for over 3 seconds. when in remote mode mouse clicks are "swallowed" by the script so
; as not to accidently affect any applications (so you can use a wireless mouse as remote control
; without looking at the computer)

; requirements:
; 1. this script requires jballi's winamp shell (http://www.autohotkey.com/forum/viewtopic.php?t=8222)
;    - download the file, name it Winamp.ahk and place it in the same directory as my script

; credits/thanks
; 1. to jballi, for his winamp AHK interface
; 2. tray icons were taken from the silk icon set, found at http://www.famfamfam.com/lab/icons/silk/

; complaints/bugs/feature-requests
; https://github.com/radai-rosenblatt/mouse-as-media-remote

; license
; this code is available under the WTFPL, version 2

; version information
; v4, 08/11/2009

; static initialization area
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force ; only one instance of this script active - double clicking it again replaces current.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include Winamp.ahk ; winamp shell by jballi (http://www.autohotkey.com/forum/viewtopic.php?t=8222)

	; global variables
	middleDownTimeStamp := 0        ; stores the time when the middle button was last pressed down
	remoteMode := false             ; mode flag. false for normal mouse mode, true for "remote" mode
	toggleThreshold := 3000         ; the amout of time required to hold down the middle button to
                                    ; toggle between normal and remote modes. in millis
	altFunctionThreshold := 1000    ; some buttons act differently if held down longer than this.
                                    ; this value MUST BE less than toggleThreshold (since the middle
                                    ; mouse button is used for toggle and has an alt function) - else
                                    ; alt functionality wont work for the middle button
	seekFrequency := 100            ; delay between consecutive seek operations (in millis)
	                                ; the larger this number is the slower seeking will be								  
	trayDisplayTime := 1000         ; number of milliseconds to disply tray action indication (play
	                                ; pause etc) before reverting back to mouse-mode tray indication
	seekPerformedFlag := false      ; flag to indicate if seeking was performed between pressing and
                                    ; releasing the right/left buttons	
; sets the initial state for the hooks
exitRemoteMode()
return

; ==================== MIDDLE BUTTON HOOKS ====================
; this is where mode-switching takes place

$MButton::
	middleDownTimeStamp := A_TickCount
	SetTimer, toggleModeLabel, -%toggleThreshold% ; negative delay means it will only fire once
	if (remoteMode) {
		; nothing, really
	} else {
		Send {MButton down}
	}
	return
	
$MButton UP::
	middleUpTimeStamp := A_TickCount
	total := A_TickCount - middleDownTimeStamp
	modeSwitched := false
	if (total < toggleThreshold) {
		; didnt hold the button down long enough to toggle mode. kill the timer.
		SetTimer, toggleModeLabel, Off
	} else {
		modeSwitched := true ; the long click that just ended was used to toggle modes
	}
	if (remoteMode) {
		; note that its quite possible the button was pressed down in normal mode and released
		; when already in remote mode (or vice versa) - in which case the active window will
        ; "see" only one of the two events (down/up)
		if (modeSwitched) {
			; put a send here to prevent active window from seeing only a down event (by firing up)
			; otherwise do nothing here (since its the click used to toggle mode, we dont want it
			; to send PLAY/PAUSE as well)
			Send {MButton up}
		} else {
			if (total > altFunctionThreshold) {
				Send {Media_Stop}
				indicateStop()
			} else {
				winampWasPlayingBefore := Winamp("Is Playing")
				Send {Media_Play_Pause}
				indicatePlayPause(winampWasPlayingBefore)
			}
		}
	} else {
		; when exiting remote mode we dont want to fire just a middle mouse up event at the
		; active window (senseless). since if the middle button was pressed in remote mode
		; the down event has not been sent, we can avoid sending up as well.
		if (modeSwitched==false) {
			Send {MButton up}
		}
	}
	return

; ==================== TIMER LABELS ====================
; "payload" labels for various timers used

; this is the "payload" for the timer we set on middle mouse down (and possibly cancel on middle up).
; it toggles the mode flag.
toggleModeLabel:
	toggleMode()
	return

; this timer payload is used to set the tray icon according to remoteMode flag
resetTrayIconLabel:
	resetTrayIcon()
	return
	
; ==================== UTILITY FUNCTIONS ====================

; toggles between remote mode and mormal mouse mode
toggleMode() {
	global remoteMode
	remoteMode := !remoteMode
	if (remoteMode) {
		enterRemoteMode()
	} else {
		exitRemoteMode()
	}	
	return
}

; sets tray icon according to mouse mode flag - either mouse or remote
resetTrayIcon() {
	global remoteMode
	if (remoteMode) {
		Menu, Tray, Icon, music.ico
	} else {
		Menu, Tray, Icon, mouse.ico
	}
	return
}

; sets tray icon to stop, schedules a tray icon reset.
indicateStop() {
	global trayDisplayTime
	Menu, Tray, Icon, control_stop.ico
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

; sets tray icon to either play or pause, depending on current winamp state
; winampInitialState - the pay.pause state _BEFORE_ the play/pause signal itself was sent
; NOTE : we dont query winamp state here ourselves because there might be a delay between
; sending play/pause to winamp and an actual change of state. so instead we query the
; state before sneding the signal and assume that it'll flip afterwards (play to pause and
; vice versa)
indicatePlayPause(winampWasPlayingBefore) {
	global trayDisplayTime
	if (winampWasPlayingBefore == 1) {
		; if it was playing before it should now be paused
		Menu, Tray, Icon, control_pause.ico
	} else {
		; if it was either paused or stopped before it should now be playing
		Menu, Tray, Icon, control_play.ico
	}
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

indicatePrev() {
	global trayDisplayTime
	Menu, Tray, Icon, control_start.ico
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

indicateNext() {
	global trayDisplayTime
	Menu, Tray, Icon, control_end.ico
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

indicateSeekBackStart() {
	Menu, Tray, Icon, control_rewind.ico
	return
}

indicateSeekForwardStart() {
	Menu, Tray, Icon, control_fastforward.ico
	return
}

indicateSeekEnd() {
	global trayDisplayTime
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

indicateVolumeUp() {
	global trayDisplayTime
	Menu, Tray, Icon, sound_add.ico
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

indicateVolumeDown() {
	global trayDisplayTime
	Menu, Tray, Icon, sound_delete.ico
	SetTimer, resetTrayIconLabel, -%trayDisplayTime%
	return
}

; this function performs the actions needed when entering remote mode (mainly registering hotkeys for
; all mouse buttons except the middle one - which always remains registered)
enterRemoteMode() {
	Hotkey, LButton, On
	Hotkey, LButton UP, On
	Hotkey, RButton, On
	Hotkey, RButton UP, On
	Hotkey, WheelDown, On
	Hotkey, WheelUp, On
	Hotkey, XButton1, On
	Hotkey, XButton2, On
	resetTrayIcon()
}

; this function performs the actions needed when exiting remote mode (mainly unregistering hotkeys for
; all mouse buttons except the middle one - which always remains registered)
exitRemoteMode() {
	Hotkey, LButton, Off
	Hotkey, LButton UP, Off
	Hotkey, RButton, Off
	Hotkey, RButton UP, Off
	Hotkey, WheelDown, Off
	Hotkey, WheelUp, Off
	Hotkey, XButton1, Off
	Hotkey, XButton2, Off
	resetTrayIcon()
}

; ==================== REMOTE MODE HOOKS ====================

LButton::
	if (!remoteMode) {
		MsgBox, LButton hook should not be registered!
		return
	}
	seekPerformedFlag := false ; reset flag
	SetTimer, seekBackward, -%altFunctionThreshold% ; negative delay means it will only fire once
	return

LButton UP::
	SetTimer, seekBackward, Off
	if (seekPerformedFlag == true) {
		indicateSeekEnd()
	} else {
		Send {Media_Prev}
		indicatePrev()
	}
	return
	
seekBackward:
	Winamp("Rewind")
	if (seekPerformedFlag == false) {
		seekPerformedFlag := true ; set flag
		indicateSeekBackStart()
	}
	SetTimer, seekBackward, -%seekFrequency% ; "loop"
	return
	
RButton::
	if (!remoteMode) {
		MsgBox, RButton hook should not be registered!
		return
	}
	seekPerformedFlag := false ; reset flag
	SetTimer, seekForward, -%altFunctionThreshold% ; negative delay means it will only fire once
	return
	
RButton UP::
	SetTimer, seekForward, Off
	if (seekPerformedFlag == true) {
		indicateSeekEnd()
	} else {
		Send {Media_Next}
		indicateNext()
	}
	return
	
seekForward:
	Winamp("Forward")
	if (seekPerformedFlag == false) {
		seekPerformedFlag := true ; set flag
		indicateSeekForwardStart()
	}
	SetTimer, seekForward, -%seekFrequency% ; "loop"
	return
	
WheelDown::
	if (!remoteMode) {
		MsgBox, WheelDown hook should not be registered!
		return
	}
	Send {Volume_Down}
	indicateVolumeDown()
	return
	
WheelUp::
	if (!remoteMode) {
		MsgBox, WheelUp hook should not be registered!
		return
	}
	Send {Volume_Up}
	indicateVolumeUp()
	return
	
XButton1::
	; not doing anything with these buttons (yet ?) - just preventing them from accidently doing anything to any active application
	if (!remoteMode) {
		MsgBox, XButton1 hook should not be registered!
	}
	return
	
XButton2::
	; not doing anything with these buttons (yet ?) - just preventing them from accidently doing anything to any active application
	if (!remoteMode) {
		MsgBox, XButton2 hook should not be registered!
	}
	return
	