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
rem
rem Pourquoi ne pas simplement lancer set_env.cmd de GnuCOBOL : il faut
rem savoir ou il est, il varie selon les distributions, et il faut penser
rem a le relancer dans chaque nouvelle fenetre. Ce script retrouve seul
rem l'installation, et cobol85.cmd l'appelle au besoin.
rem
rem Consequence de l'absence de setlocal : toutes les variables de travail
rem sont prefixees fx_, pour ne pas ecraser celles de l'appelant, puis
rem videes a la sortie, pour ne pas laisser de traces dans la session.

set "fx_root="
set "fx_persist="
rem Arguments dans n'importe quel ordre : /persist est reconnu, tout le
rem reste est pris comme dossier. %~f1 le rend absolu, car un chemin
rem relatif ne vaudrait plus rien dans une autre fenetre avec /persist.
:fx_parse
if "%~1"=="" goto fx_parsed
if /i "%~1"=="/persist" (set "fx_persist=1") else set "fx_root=%~f1"
shift
goto fx_parse
:fx_parsed

rem Racine : parent du dossier de cobc.exe trouve dans le PATH
rem Ordre de recherche : dossier donne > cobc du PATH > emplacements
rem habituels. Le cobc du PATH passe avant les emplacements par defaut :
rem c'est lui qui sera execute, sa config doit donc etre la sienne.
rem "if not defined fx_root" dans la boucle : "where" peut renvoyer
rem plusieurs cobc, on garde le premier, celui que cmd lancerait.
rem 2^>nul : le ^ empeche cmd d'appliquer la redirection au "for" lui-meme.
if defined fx_root goto fx_find_cfg
for /f "delims=" %%F in ('where cobc 2^>nul') do if not defined fx_root set "fx_root=%%~dpF.."
if defined fx_root goto fx_find_cfg
rem Emplacements des distributions courantes, dont les installeurs sans
rem droits admin, qui s'installent sous le profil utilisateur.
for %%D in ("C:\GnuCOBOL" "C:\gnucobol" "%ProgramFiles%\GnuCOBOL" "%ProgramFiles(x86)%\GnuCOBOL" "%LOCALAPPDATA%\GnuCOBOL" "%USERPROFILE%\GnuCOBOL") do (
    if not defined fx_root if exist "%%~D\bin\cobc.exe" set "fx_root=%%~D"
)
if not defined fx_root (
    echo Erreur: GnuCOBOL introuvable, passer son dossier en argument 1>&2
    echo   ex : cobol85-fixenv.cmd C:\GnuCOBOL 1>&2
    goto fx_fail
)

rem Normalise la racine : %%~fD resout le "bin\.." venu de where, et le
rem "\" final est retire pour pouvoir ecrire "%fx_root%\config".
:fx_find_cfg
for %%D in ("%fx_root%") do set "fx_root=%%~fD"
if "%fx_root:~-1%"=="\" set "fx_root=%fx_root:~0,-1%"
rem Le dossier config change selon la distribution : config\ pour les
rem builds MinGW "a plat", share\gnucobol\config\ pour une arborescence
rem Unix, bin\config\ pour certaines archives. On teste cobol85.conf,
rem le fichier dont cobol85.cmd a besoin avec -std=cobol85.
set "fx_cfg="
for %%D in ("%fx_root%\config" "%fx_root%\share\gnucobol\config" "%fx_root%\bin\config") do (
    if not defined fx_cfg if exist "%%~D\cobol85.conf" set "fx_cfg=%%~fD"
)
if not defined fx_cfg goto fx_no_cfg

rem Deja configure par un appel precedent : on ne rajoute pas les flags
rem Les lignes COB_CFLAGS/COB_LDFLAGS plus bas ajoutent en tete de la
rem valeur existante : sans ce test, chaque appel les dupliquerait.
if /i "%COB_CONFIG_DIR%"=="%fx_cfg%" goto fx_path

rem COB_MAIN_DIR avec "\" final : c'est la forme qu'utilise set_env.cmd.
rem COB_COPY_DIR : dossier des COPY de GnuCOBOL. COB_LIBRARY_PATH :
rem modules appeles par CALL dynamique. Definis seulement s'ils existent,
rem pour ne pas pointer cobc vers un dossier absent.
set "COB_MAIN_DIR=%fx_root%\"
set "COB_CONFIG_DIR=%fx_cfg%"
if exist "%fx_root%\copy" set "COB_COPY_DIR=%fx_root%\copy"
if exist "%fx_root%\share\gnucobol\copy" set "COB_COPY_DIR=%fx_root%\share\gnucobol\copy"
if exist "%fx_root%\extras" set "COB_LIBRARY_PATH=%fx_root%\extras"
rem Memes chemins /mingw compiles en dur pour libcob.h et libcob.a
rem Sans eux, gcc, appele par cobc sur le C genere, ne trouve ni
rem l'en-tete ni la bibliotheque du runtime COBOL.
if exist "%fx_root%\include\libcob.h" set "COB_CFLAGS=-I"%fx_root%\include" %COB_CFLAGS%"
if exist "%fx_root%\lib" set "COB_LDFLAGS=-L"%fx_root%\lib" %COB_LDFLAGS%"

rem bin\ ajoute au PATH seulement si cobc n'y est pas deja : sinon on
rem risquerait de passer devant une autre installation choisie par
rem l'utilisateur. bin\ contient aussi les DLL du runtime (libcob...).
:fx_path
where cobc >nul 2>&1
if errorlevel 1 if exist "%fx_root%\bin\cobc.exe" set "PATH=%fx_root%\bin;%PATH%"

rem Affiche ce qui a ete retenu : utile pour comprendre quelle
rem installation est utilisee quand plusieurs coexistent.
echo GnuCOBOL : %fx_root%
echo COB_CONFIG_DIR=%COB_CONFIG_DIR%
if defined COB_COPY_DIR echo COB_COPY_DIR=%COB_COPY_DIR%

rem setx n'affecte que les prochaines fenetres, pas celle-ci : c'est pour
rem cela que les "set" ci-dessus restent necessaires dans tous les cas.
rem COB_CFLAGS, COB_LDFLAGS et PATH ne sont volontairement pas
rem enregistres : setx tronque a 1024 caracteres et fige des valeurs
rem combinees qu'on ne pourrait plus nettoyer facilement.
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

rem Deux sorties qui vident les variables fx_ : pas de setlocal, donc
rem sans cela elles resteraient visibles dans la fenetre de l'utilisateur.
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
