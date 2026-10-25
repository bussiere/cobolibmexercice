@echo off
rem Compile et execute un fichier COBOL en norme COBOL 85 (ANSI X3.23-1985
rem + amendement X3.23a-1989 : fonctions intrinseques). Version Windows.
rem Usage : cobol85.cmd [-i source[:nom]]... fichier.cbl [args du programme...]
rem -i : fichier (ou dossier) d'entree, repetable. Copie dans le dossier
rem      du .cbl sous "nom" (defaut : nom de la source), soit le nom du
rem      ASSIGN TO du SELECT COBOL, puis supprime en fin d'execution.
rem      Les options -i se placent avant fichier.cbl.
rem      Ex : cobol85.cmd -i char_input1.txt:char_input.txt inpsni1.cbl
rem           cobol85.cmd -i C:\data\a.txt -i b.dat:CLIENTS prog.cbl
rem Le programme s'execute dans le dossier du .cbl (comme dans le pod).
rem Necessite GnuCOBOL (cobc) dans le PATH (set_env.cmd de GnuCOBOL).
setlocal EnableExtensions EnableDelayedExpansion

set "n_in=0"
set "n_tmp=0"
set "pushed="
set "rc=0"

:parse_opts
if [%1]==[] goto usage
if /i "%~1"=="-i" goto opt_input
if /i "%~1"=="--input" goto opt_input
if "%~1"=="--" (shift & goto end_opts)
set "arg1=%~1"
if "!arg1:~0,1!"=="-" goto usage
goto end_opts

:opt_input
if [%2]==[] goto usage
set /a n_in+=1
set "in_spec[!n_in!]=%~2"
shift & shift
goto parse_opts

:end_opts
if [%1]==[] goto usage
if not exist "%~1" (
    echo Erreur: fichier introuvable: %~1 1>&2
    exit /b 1
)
if exist "%~1\*" (
    echo Erreur: fichier introuvable: %~1 1>&2
    exit /b 1
)
rem src_dir garde son "\" final
for %%F in ("%~1") do (
    set "src_dir=%%~dpF"
    set "src_name=%%~nxF"
    set "exe_name=%%~nF"
)
shift

rem Arguments restants : passes tels quels au programme
set "prog_args="
:collect_args
if [%1]==[] goto args_done
set prog_args=!prog_args! %1
shift
goto collect_args
:args_done

where cobc >nul 2>&1
if errorlevel 1 (
    echo Erreur: cobc GnuCOBOL introuvable, lancer set_env.cmd de GnuCOBOL 1>&2
    exit /b 1
)

rem Fichiers d'entree : copies dans le dossier du .cbl sous <nom>
for /l %%k in (1,1,%n_in%) do (
    call :prep_input %%k
    if errorlevel 1 (
        set "rc=1"
        goto cleanup
    )
)

if not exist "%src_dir%build" mkdir "%src_dir%build"
pushd "%src_dir%"
set "pushed=1"

rem -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989)
rem -x : executable ; -Wall : avertissements ; -fixed : format fixe colonnes 8-72
call cobc -x -std=cobol85 -fixed -Wall -o "build\%exe_name%.exe" "%src_name%"
if errorlevel 1 (
    set "rc=!errorlevel!"
    goto cleanup
)
echo === Execution de %exe_name% ===
"build\%exe_name%.exe"%prog_args%
set "rc=%errorlevel%"

:cleanup
if defined pushed popd
for /l %%k in (1,1,%n_tmp%) do call :remove_tmp %%k
exit /b %rc%

rem Supprime la copie d'entree n %1 (fichier ou dossier)
:remove_tmp
set "p=!tmp[%~1]!"
if exist "%p%\*" rmdir /s /q "%p%"
if exist "%p%" del /f /q "%p%"
exit /b 0

:usage
echo Usage: %~nx0 [-i source[:nom]]... fichier.cbl [args...] 1>&2
exit /b 1

rem Prepare l'entree n %1, "source[:nom]". La source peut commencer par une
rem lettre de lecteur (C:\...) : on la met de cote avant de couper sur ":".
:prep_input
set "spec=!in_spec[%~1]!"
set "drv="
set "rest=%spec%"
if "%spec:~1,1%"==":" (
    set "drv=%spec:~0,2%"
    set "rest=%spec:~2%"
)
set "in_src="
set "in_name="
for /f "tokens=1,* delims=:" %%a in ("%rest%") do (
    set "in_src=%drv%%%a"
    set "in_name=%%b"
)
if not defined in_src (
    echo Erreur: entree invalide: %spec% 1>&2
    exit /b 1
)
if not defined in_name for %%F in ("%in_src%") do set "in_name=%%~nxF"
if not exist "%in_src%" (
    echo Erreur: entree introuvable: %in_src% 1>&2
    exit /b 1
)
set "chk=!in_name:\=!"
set "chk=!chk:/=!"
set "chk=!chk::=!"
if not "!chk!"=="!in_name!" set "chk="
if "!in_name:~0,1!"=="." set "chk="
if not defined chk (
    echo Erreur: nom d'entree invalide: %in_name% 1>&2
    exit /b 1
)
for %%F in ("%in_src%") do set "in_abs=%%~fF"
for %%F in ("%src_dir%%in_name%") do set "dest=%%~fF"
rem Source deja a sa place : rien a copier
if /i "%in_abs%"=="%dest%" exit /b 0
rem Pas de montage par-dessus comme Podman : on refuse d'ecraser
if exist "%dest%" (
    echo Erreur: %dest% existe deja, refus de l'ecraser 1>&2
    exit /b 1
)
set /a n_tmp+=1
set "tmp[%n_tmp%]=%dest%"
if exist "%in_abs%\*" (
    xcopy "%in_abs%" "%dest%\" /e /i /q /y >nul
) else (
    copy /y "%in_abs%" "%dest%" >nul
)
if errorlevel 1 (
    echo Erreur: copie impossible: %in_abs% 1>&2
    exit /b 1
)
exit /b 0
