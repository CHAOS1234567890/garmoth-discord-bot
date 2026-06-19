; BDO Automation Installer (NSIS)
; Requires: NSIS 3.0+

!include "MUI2.nsh"
!include "x64.nsh"

; Basic Settings
Name "BDO Automation Tool"
OutFile "BDO_Automation_Setup.exe"
InstallDir "$PROGRAMFILES\BDOAutomation"
InstallDirRegKey HKLM "Software\BDOAutomation" "InstallPath"

; Request admin privileges
RequestExecutionLevel admin

; Variables
Var StartMenuFolder

; MUI Settings
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU "Application" $StartMenuFolder
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "German"

; Installer Sections
Section "Install BDO Automation" SecInstall
  SetOutPath "$INSTDIR"
  
  ; Create directory structure
  CreateDirectory "$INSTDIR\etc"
  CreateDirectory "$INSTDIR\usr\lib\bdo"
  CreateDirectory "$INSTDIR\usr\bin"
  CreateDirectory "$INSTDIR\scripts"
  
  ; Extract embedded files
  File "bdo_setup.sh"
  File "bdo_launcher.ahk"
  File "bdo_config.ini"
  
  ; Create bdo.conf
  FileOpen $0 "$INSTDIR\etc\bdo.conf" w
  FileWrite $0 "MODE=`"mixed`"$\r$\n"
  FileWrite $0 "USE_BUFFS=1$\r$\n"
  FileWrite $0 "USE_POTS=1$\r$\n"
  FileWrite $0 "AUTO_REPAIR=1$\r$\n"
  FileWrite $0 "AUTO_SELL_TRASH=1$\r$\n"
  FileWrite $0 "HUMANIZE=1$\r$\n"
  FileWrite $0 "LOGFILE=`"$INSTDIR\logs\bdo.log`"$\r$\n"
  FileWrite $0 "SCREEN_WIDTH=1920$\r$\n"
  FileWrite $0 "SCREEN_HEIGHT=1080$\r$\n"
  FileWrite $0 "FISH_WAIT_MIN=2$\r$\n"
  FileWrite $0 "FISH_WAIT_MAX=5$\r$\n"
  FileWrite $0 "GRIND_DURATION=1800$\r$\n"
  FileWrite $0 "FISH_DURATION=1800$\r$\n"
  FileClose $0
  
  ; Create logs directory
  CreateDirectory "$INSTDIR\logs"
  
  ; Register in Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BDOAutomation" "DisplayName" "BDO Automation Tool"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BDOAutomation" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BDOAutomation" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BDOAutomation" "DisplayVersion" "1.0.0"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BDOAutomation" "Publisher" "CHAOS1234567890"
  
  WriteRegStr HKLM "Software\BDOAutomation" "InstallPath" "$INSTDIR"
  
  ; Create Uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Create Start Menu shortcuts
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\BDO Automation.lnk" "$INSTDIR\bdo.exe"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Config.lnk" "$INSTDIR\etc\bdo.conf"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END
  
  SetOverwrite off
  File "bdo.exe"
  
SectionEnd

; Uninstall Section
Section "Uninstall"
  
  ; Delete files
  Delete "$INSTDIR\bdo.exe"
  Delete "$INSTDIR\bdo_setup.sh"
  Delete "$INSTDIR\bdo_launcher.ahk"
  Delete "$INSTDIR\bdo_config.ini"
  Delete "$INSTDIR\etc\bdo.conf"
  Delete "$INSTDIR\Uninstall.exe"
  
  ; Delete directories
  RMDir "$INSTDIR\etc"
  RMDir "$INSTDIR\usr\lib\bdo"
  RMDir "$INSTDIR\usr\bin"
  RMDir "$INSTDIR\usr\lib"
  RMDir "$INSTDIR\usr"
  RMDir "$INSTDIR\scripts"
  RMDir "$INSTDIR\logs"
  RMDir "$INSTDIR"
  
  ; Delete shortcuts
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  RMDir /r "$SMPROGRAMS\$StartMenuFolder"
  
  ; Delete registry entries
  DeleteRegKey HKLM "Software\BDOAutomation"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BDOAutomation"
  
SectionEnd
