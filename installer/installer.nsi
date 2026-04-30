!include MUI2.nsi

!define MUI_ICON "..\icon\syslogfui.ico"
!define MUI_UNICON "..\icon\syslogfui.ico"
Var IconPath

!ifndef RELEASE_BASE
  !define RELEASE_BASE "unknown"
!endif

!ifndef DISPLAY_VERSION
  !define DISPLAY_VERSION "${RELEASE_BASE}"
!endif

!ifndef CONTENTS_DIR
  !define CONTENTS_DIR "installer_stage"
!endif

!define APP_NAME "SyslogFUI"
!define INSTALL_DIR_D "D:\Program Files\SyslogFUI"
!define INSTALL_DIR_C "C:\Program Files\SyslogFUI"
!define INSTALL_DIR_PF "$PROGRAMFILES\SyslogFUI"
!define REGKEY_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\SyslogFUI"

!ifndef LAUNCHER
  !define LAUNCHER "syslogfui.exe"
!endif

!ifndef OUTPUT_NAME
  !define OUTPUT_NAME "syslogfui-${RELEASE_BASE}-windows-x64-installer.exe"
!endif

Name "${APP_NAME}"
!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "."
!endif
OutFile "${OUTPUT_DIR}\${OUTPUT_NAME}"
InstallDir "${INSTALL_DIR_D}"
InstallDirRegKey HKLM "${REGKEY_UNINSTALL}" "InstallLocation"
RequestExecutionLevel admin

Function .onInit
  ; Try D: drive first
  StrCpy $INSTDIR "${INSTALL_DIR_D}"
  IfFileExists "D:\*" 0 +2
    Goto done
  ; D: doesn't exist, try C:
  StrCpy $INSTDIR "${INSTALL_DIR_C}"
  IfFileExists "C:\*" 0 +2
    Goto done
  ; Both D: and C: unavailable, use Program Files
  StrCpy $INSTDIR "${INSTALL_DIR_PF}"
  done:
  StrCpy $R0 $mui.Header.Text
  StrCpy $R0 $mui.Header.Text.Font
  StrCpy $R0 $mui.Header.SubText
  StrCpy $R0 $mui.Header.Background
  StrCpy $R0 $mui.Header.Image
  StrCpy $R0 $mui.Branding.Text
  StrCpy $R0 $mui.Branding.Background
  StrCpy $R0 $mui.Line.Standard
  StrCpy $R0 $mui.Line.FullWindow
  StrCpy $R0 $mui.Button.Next
  StrCpy $R0 $mui.Button.Cancel
  StrCpy $R0 $mui.Button.Back
FunctionEnd

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${CONTENTS_DIR}\*"

  CreateDirectory "$SMPROGRAMS\SyslogFUI"

  StrCpy $IconPath "$INSTDIR\icon.ico"
  IfFileExists "$IconPath" 0 +3
    Goto haveIcon
  StrCpy $IconPath "$INSTDIR\assets\app_icon.png"
  IfFileExists "$IconPath" 0 +3
    Goto haveIcon
  StrCpy $IconPath "$INSTDIR\${LAUNCHER}"
  haveIcon:

  CreateShortcut "$SMPROGRAMS\SyslogFUI\SyslogFUI.lnk" "$INSTDIR\${LAUNCHER}" "" "$IconPath" 0

  WriteUninstaller "$INSTDIR\uninstall.exe"

  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "DisplayVersion" "${DISPLAY_VERSION}"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "Publisher" "SyslogFUI"
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\SyslogFUI\SyslogFUI.lnk"
  RMDir "$SMPROGRAMS\SyslogFUI"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKLM "${REGKEY_UNINSTALL}"
SectionEnd