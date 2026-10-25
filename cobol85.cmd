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
rem
rem Equivalent de cobol85.sh, avec en plus l'option -i de cobol85-podman.sh.
rem Pas de montage sous Windows : les entrees sont copiees, puis effacees.
rem
rem Pieges de cmd a connaitre pour lire ce script :
rem - Les %var% d'un bloc ( ... ) sont remplaces une seule fois, a la
rem   lecture du bloc entier : dans une boucle ou un if, il faut !var!
rem   (expansion retardee) pour voir la valeur courante.
rem - Pas de tableaux : on simule in_spec[1], in_spec[2]... avec des
rem   noms de variables, relus par !in_spec[%%k]!.
rem - Pas de fonctions : "call :etiquette" + "exit /b" en tiennent lieu.

rem setlocal : toutes les variables du script disparaissent a la fin, sans
rem polluer la fenetre cmd de l'utilisateur (le cd de pushd aussi).
rem EnableDelayedExpansion : active la syntaxe !var! (voir plus haut).
setlocal EnableExtensions EnableDelayedExpansion

rem %~dp0 = dossier du script : retrouve cobol85-fixenv.cmd quel que soit
rem le repertoire depuis lequel on lance cobol85.cmd.
set "script_dir=%~dp0"
rem n_in : nombre d'options -i ; n_tmp : nombre de copies a effacer a la
rem fin ; pushed : vrai une fois le pushd fait, pour ne faire popd que la.
set "n_in=0"
set "n_tmp=0"
set "pushed="
set "rc=0"

rem Lecture des options du script. On s'arrete au premier argument qui
rem n'est pas une option (le .cbl) : tout ce qui suit appartient au
rem programme COBOL, meme s'il commence par "-". "--" force cet arret.
rem [%1]==[] plutot que "%~1"=="" : reste valable si l'argument contient
rem des guillemets.
:parse_opts
if [%1]==[] goto usage
if /i "%~1"=="-i" goto opt_input
if /i "%~1"=="--input" goto opt_input
if "%~1"=="--" (shift & goto end_opts)
rem Passage par une variable : cmd ne sait pas extraire un caractere de %1
set "arg1=%~1"
if "!arg1:~0,1!"=="-" goto usage
goto end_opts

rem On ne fait que memoriser la valeur : elle est analysee plus tard par
rem :prep_input, une fois connu le dossier du .cbl ou copier.
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
rem "if exist" est vrai aussi pour un dossier ; "dossier\*" n'existe que
rem pour un dossier, d'ou ce test pour refuser un dossier comme source.
if exist "%~1\*" (
    echo Erreur: fichier introuvable: %~1 1>&2
    exit /b 1
)
rem src_dir garde son "\" final
rem Ainsi "%src_dir%build" est correct meme a la racine d'un disque, ou
rem retirer le "\" donnerait "C:" qui designe le dossier courant de C:.
rem %%~dpF : lecteur+dossier, %%~nxF : nom+extension, %%~nF : nom seul.
for %%F in ("%~1") do (
    set "src_dir=%%~dpF"
    set "src_name=%%~nxF"
    set "exe_name=%%~nF"
)
shift

rem Arguments restants : passes tels quels au programme
rem %* ne tient pas compte des shift : il faut reconstruire la liste a la
rem main. %1 et non %~1, pour garder les guillemets d'un "a b".
set "prog_args="
:collect_args
if [%1]==[] goto args_done
set prog_args=!prog_args! %1
shift
goto collect_args
:args_done

rem Sans COB_CONFIG_DIR, cobc cherche sa config sous /mingw/... : erreur
rem Le test evite de refaire la configuration si set_env.cmd de GnuCOBOL,
rem ou un appel precedent, l'a deja faite dans cette fenetre.
if not defined COB_CONFIG_DIR call "%script_dir%cobol85-fixenv.cmd"
rem Verifie avant d'appeler cobc pour un message utile au lieu de
rem "n'est pas reconnu en tant que commande interne".
where cobc >nul 2>&1
if errorlevel 1 (
    echo Erreur: cobc GnuCOBOL introuvable, lancer set_env.cmd de GnuCOBOL 1>&2
    exit /b 1
)

rem Fichiers d'entree : copies dans le dossier du .cbl sous <nom>
rem Fait avant le pushd : les chemins relatifs des -i sont ceux du
rem repertoire de l'appelant. On passe l'indice et non la valeur a
rem :prep_input, "call" re-expandant les % et ^ d'une valeur.
rem En cas d'erreur, on passe quand meme par :cleanup pour effacer les
rem copies deja faites par les -i precedents.
for /l %%k in (1,1,%n_in%) do (
    call :prep_input %%k
    if errorlevel 1 (
        set "rc=1"
        goto cleanup
    )
)

rem build\ a cote du source, comme les scripts sh, et ignore par git
if not exist "%src_dir%build" mkdir "%src_dir%build"
rem pushd : le programme s'execute dans le dossier du .cbl, comme dans le
rem pod, pour que les ASSIGN TO relatifs trouvent les entrees copiees.
pushd "%src_dir%"
set "pushed=1"

rem -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989)
rem -x : executable ; -Wall : avertissements ; -fixed : format fixe colonnes 8-72
rem ".exe" explicite : le nom produit doit etre exactement celui lance
rem plus bas, sans dependre de ce que cobc ajoute ou non comme extension.
rem "call" : si cobc est un .bat/.cmd (certaines distributions), sans call
rem la main ne reviendrait jamais a ce script.
call cobc -x -std=cobol85 -fixed -Wall -o "build\%exe_name%.exe" "%src_name%"
rem !errorlevel! et non %errorlevel% : on est dans un bloc ( ... )
if errorlevel 1 (
    set "rc=!errorlevel!"
    goto cleanup
)
echo === Execution de %exe_name% ===
rem Pas d'espace avant %prog_args% : la variable commence deja par un espace
"build\%exe_name%.exe"%prog_args%
rem Code retour du programme COBOL (STOP RUN / RETURN-CODE) garde pour la fin
set "rc=%errorlevel%"

rem Point de sortie unique, atteint aussi en cas d'erreur, pour toujours
rem revenir au dossier de depart et effacer les copies d'entree.
:cleanup
if defined pushed popd
for /l %%k in (1,1,%n_tmp%) do call :remove_tmp %%k
exit /b %rc%

rem Supprime la copie d'entree n %1 (fichier ou dossier)
rem Deux "if" simples plutot que "if ... else if" : plus lisible, et
rem apres rmdir le second test est faux de toute facon.
rem del /f : la copie peut etre en lecture seule si la source l'etait.
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
rem Sinon "C:\data\a.txt:CLIENTS" serait coupe en "C" et "\data\...".
:prep_input
set "spec=!in_spec[%~1]!"
set "drv="
set "rest=%spec%"
if "%spec:~1,1%"==":" (
    set "drv=%spec:~0,2%"
    set "rest=%spec:~2%"
)
rem Remise a vide : ces variables gardent la valeur de l'entree precedente
set "in_src="
set "in_name="
rem tokens=1,* : %%a = avant le premier ":", %%b = tout le reste
for /f "tokens=1,* delims=:" %%a in ("%rest%") do (
    set "in_src=%drv%%%a"
    set "in_name=%%b"
)
if not defined in_src (
    echo Erreur: entree invalide: %spec% 1>&2
    exit /b 1
)
rem Sans ":nom", le nom est celui de la source : cas ou il correspond
rem deja au ASSIGN TO.
if not defined in_name for %%F in ("%in_src%") do set "in_name=%%~nxF"
if not exist "%in_src%" (
    echo Erreur: entree introuvable: %in_src% 1>&2
    exit /b 1
)
rem Le nom doit rester dans le dossier du .cbl : un "\", "/" ou ":" ferait
rem copier ailleurs, et un nom en "." est surement une erreur. On retire
rem ces caracteres : si le nom change, c'est qu'il en contenait. Fait en
rem cmd pur plutot qu'avec findstr, dont le support des regex varie.
set "chk=!in_name:\=!"
set "chk=!chk:/=!"
set "chk=!chk::=!"
if not "!chk!"=="!in_name!" set "chk="
if "!in_name:~0,1!"=="." set "chk="
if not defined chk (
    echo Erreur: nom d'entree invalide: %in_name% 1>&2
    exit /b 1
)
rem %%~fF : chemin complet normalise, pour comparer deux chemins ecrits
rem differemment, en relatif ou en absolu.
for %%F in ("%in_src%") do set "in_abs=%%~fF"
for %%F in ("%src_dir%%in_name%") do set "dest=%%~fF"
rem Source deja a sa place : rien a copier
rem Surtout pas de copie : la copie serait effacee a la fin, et avec elle
rem le fichier de l'utilisateur. /i : chemins Windows insensibles a la casse.
if /i "%in_abs%"=="%dest%" exit /b 0
rem Pas de montage par-dessus comme Podman : on refuse d'ecraser
rem Podman masque le fichier existant le temps de l'execution ; une copie
rem le remplacerait, puis le nettoyage final l'effacerait : perte de donnee.
if exist "%dest%" (
    echo Erreur: %dest% existe deja, refus de l'ecraser 1>&2
    exit /b 1
)
rem Enregistre avant la copie : si elle echoue a moitie, par exemple un
rem dossier partiellement copie, le nettoyage efface quand meme le reste.
set /a n_tmp+=1
set "tmp[%n_tmp%]=%dest%"
rem xcopy pour un dossier : copy ne sait pas copier recursivement.
rem /e : sous-dossiers meme vides ; /i : la cible est un dossier, sans
rem question interactive ; /q : silencieux ; /y : pas de confirmation.
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
