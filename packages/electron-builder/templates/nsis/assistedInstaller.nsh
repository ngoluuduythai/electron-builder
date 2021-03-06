!include UAC.nsh

!ifndef INSTALL_MODE_PER_ALL_USERS
  !include multiUserUi.nsh
!endif

!ifndef BUILD_UNINSTALLER
  Function StartApp
    ${if} ${isUpdated}
      ${StdUtils.ExecShellAsUser} $0 "$launchLink" "open" "--updated"
    ${else}
      ${StdUtils.ExecShellAsUser} $0 "$launchLink" "open" ""
    ${endif}
  FunctionEnd

  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_FUNCTION "StartApp"

  !ifmacrodef licensePage
    !insertmacro licensePageHelper
    !insertmacro licensePage
  !endif

  !ifndef INSTALL_MODE_PER_ALL_USERS
    !insertmacro PAGE_INSTALL_MODE
  !endif

  !ifdef allowToChangeInstallationDirectory
    !include StrContains.nsh

    !insertmacro MUI_PAGE_DIRECTORY

    # pageDirectory leave doesn't work (it seems because $INSTDIR is set after custom leave function)
    # so, we yse instfiles pre
    !define MUI_PAGE_CUSTOMFUNCTION_PRE instFilesPre

    # Sanitize the MUI_PAGE_DIRECTORY result to make sure it has a application name sub-folder
    Function instFilesPre
      ${If} ${FileExists} "$INSTDIR\*"
        ${StrContains} $0 "${APP_FILENAME}" $INSTDIR
        ${If} $0 == ""
          StrCpy $INSTDIR "$INSTDIR\${APP_FILENAME}"
        ${endIf}
      ${endIf}
    FunctionEnd
  !endif
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
!else
  !insertmacro MUI_UNPAGE_WELCOME
  !ifndef INSTALL_MODE_PER_ALL_USERS
    !insertmacro PAGE_INSTALL_MODE
  !endif
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH
!endif

!macro initMultiUser
  !ifdef INSTALL_MODE_PER_ALL_USERS
    !insertmacro setInstallModePerAllUsers
  !else
    ${If} ${UAC_IsInnerInstance}
    ${AndIfNot} ${UAC_IsAdmin}
      # special return value for outer instance so it knows we did not have admin rights
      SetErrorLevel 0x666666
      Quit
    ${endIf}

    !ifndef MULTIUSER_INIT_TEXT_ADMINREQUIRED
      !define MULTIUSER_INIT_TEXT_ADMINREQUIRED "$(^Caption) requires administrator privileges."
    !endif

    !ifndef MULTIUSER_INIT_TEXT_POWERREQUIRED
      !define MULTIUSER_INIT_TEXT_POWERREQUIRED "$(^Caption) requires at least Power User privileges."
    !endif

    !ifndef MULTIUSER_INIT_TEXT_ALLUSERSNOTPOSSIBLE
      !define MULTIUSER_INIT_TEXT_ALLUSERSNOTPOSSIBLE "Your user account does not have sufficient privileges to install $(^Name) for all users of this computer."
    !endif

    # checks registry for previous installation path (both for upgrading, reinstall, or uninstall)
    StrCpy $hasPerMachineInstallation "0"
    StrCpy $hasPerUserInstallation "0"

    # set installation mode to setting from a previous installation
    ReadRegStr $perMachineInstallationFolder HKLM "${INSTALL_REGISTRY_KEY}" InstallLocation
    ${if} $perMachineInstallationFolder != ""
      StrCpy $hasPerMachineInstallation "1"
    ${endif}

    ReadRegStr $perUserInstallationFolder HKCU "${INSTALL_REGISTRY_KEY}" InstallLocation
    ${if} $perUserInstallationFolder != ""
      StrCpy $hasPerUserInstallation "1"
    ${endif}

    ${GetParameters} $R0
    ${GetOptions} $R0 "/allusers" $R1
    ${IfNot} ${Errors}
      StrCpy $hasPerMachineInstallation "1"
      StrCpy $hasPerUserInstallation "0"
    ${EndIf}

    ${GetOptions} $R0 "/currentuser" $R1
    ${IfNot} ${Errors}
      StrCpy $hasPerMachineInstallation "0"
      StrCpy $hasPerUserInstallation "1"
    ${EndIf}

    ${if} $hasPerUserInstallation == "1"
    ${andif} $hasPerMachineInstallation == "0"
      !insertmacro setInstallModePerUser
    ${elseif} $hasPerUserInstallation == "0"
      ${andif} $hasPerMachineInstallation == "1"
      !insertmacro setInstallModePerAllUsers
    ${else}
      # if there is no installation, or there is both per-user and per-machine
      !ifdef INSTALL_MODE_PER_ALL_USERS
        !insertmacro setInstallModePerAllUsers
      !else
        !insertmacro setInstallModePerUser
      !endif
    ${endif}
  !endif
!macroend
