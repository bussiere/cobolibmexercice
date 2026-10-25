@echo off
rem Corrige sous Windows l'erreur GnuCOBOL :
rem   configuration error:
rem   /mingw/share/gnucobol/config\cobol85.conf: No such file or directory
rem Le cobc MinGW cherche sa config dans son chemin de compilation
rem (/mingw/...) quand COB_CONFIG_DIR n'est pas defini. On definit les
rem variables COB_* vers l'installation reelle (comme set_env.cmd).
rem Usage : cobol85-fixenv.cmd [dossier_gnucobol] [/persist]
rem   dossier_gnucobol : racine GnuCOBOL (defaut : deduite de cobc du PATH,
rem                      sinon C:\GnuCOBOL, %ProgramFiles%\GnuCOBOL...)
rem   /persist         : enregistre aussi les dossiers (setx, compte
rem                      utilisateur, sans droits admin) pour les
rem                      prochaines fenetres cmd
rem Depuis un autre script : call cobol85-fixenv.cmd
rem Pas de setlocal : les variables doivent rester dans la session.

set "fx_root="
set "fx_persist="
:fx_parse
if "%~1"=="" goto fx_parsed
if /i "%~1"=="/persist" (set "fx_persist=1") else set "fx_root=%~f1"
shift
goto fx_parse
:fx_parsed

rem Racine : parent du dossier de cobc.exe trouve dans le PATH
if defined fx_root goto fx_find_cfg
for /f "delims=" %%F in ('where cobc 2^>nul') do if not defined fx_root set "fx_root=%%~dpF.."
if defined fx_root goto fx_find_cfg
for %%D in ("C:\GnuCOBOL" "C:\gnucobol" "%ProgramFiles%\GnuCOBOL" "%ProgramFiles(x86)%\GnuCOBOL" "%LOCALAPPDATA%\GnuCOBOL" "%USERPROFILE%\GnuCOBOL") do (
    if not defined fx_root if exist "%%~D\bin\cobc.exe" set "fx_root=%%~D"
)
if not defined fx_root (
    echo Erreur: GnuCOBOL introuvable, passer son dossier en argument 1>&2
    echo   ex : cobol85-fixenv.cmd C:\GnuCOBOL 1>&2
    goto fx_fail
)

:fx_find_cfg
for %%D in ("%fx_root%") do set "fx_root=%%~fD"
if "%fx_root:~-1%"=="\" set "fx_root=%fx_root:~0,-1%"
set "fx_cfg="
for %%D in ("%fx_root%\config" "%fx_root%\share\gnucobol\config" "%fx_root%\bin\config") do (
    if not defined fx_cfg if exist "%%~D\cobol85.conf" set "fx_cfg=%%~fD"
)
if not defined fx_cfg goto fx_no_cfg

rem Deja configure par un appel precedent : on ne rajoute pas les flags
if /i "%COB_CONFIG_DIR%"=="%fx_cfg%" goto fx_path

set "COB_MAIN_DIR=%fx_root%\"
set "COB_CONFIG_DIR=%fx_cfg%"
if exist "%fx_root%\copy" set "COB_COPY_DIR=%fx_root%\copy"
if exist "%fx_root%\share\gnucobol\copy" set "COB_COPY_DIR=%fx_root%\share\gnucobol\copy"
if exist "%fx_root%\extras" set "COB_LIBRARY_PATH=%fx_root%\extras"
rem Memes chemins /mingw compiles en dur pour libcob.h et libcob.a
if exist "%fx_root%\include\libcob.h" set "COB_CFLAGS=-I"%fx_root%\include" %COB_CFLAGS%"
if exist "%fx_root%\lib" set "COB_LDFLAGS=-L"%fx_root%\lib" %COB_LDFLAGS%"

:fx_path
where cobc >nul 2>&1
if errorlevel 1 if exist "%fx_root%\bin\cobc.exe" set "PATH=%fx_root%\bin;%PATH%"

echo GnuCOBOL : %fx_root%
echo COB_CONFIG_DIR=%COB_CONFIG_DIR%
if defined COB_COPY_DIR echo COB_COPY_DIR=%COB_COPY_DIR%

if not defined fx_persist goto fx_ok
setx COB_MAIN_DIR "%fx_root%" >nul
setx COB_CONFIG_DIR "%COB_CONFIG_DIR%" >nul
if defined COB_COPY_DIR setx COB_COPY_DIR "%COB_COPY_DIR%" >nul
if defined COB_LIBRARY_PATH setx COB_LIBRARY_PATH "%COB_LIBRARY_PATH%" >nul
echo Variables enregistrees pour les prochaines fenetres cmd.
goto fx_ok

:fx_no_cfg
echo Erreur: cobol85.conf introuvable sous %fx_root% 1>&2
echo   (cherche dans config\ et share\gnucobol\config\) 1>&2
goto fx_fail

:fx_ok
set "fx_root="
set "fx_cfg="
set "fx_persist="
exit /b 0

:fx_fail
set "fx_root="
set "fx_cfg="
set "fx_persist="
exit /b 1
