@echo off
rem script surtout present pour se rappeler la syntaxe
rem inpsni1.cbl lit "char_input1.txt" (ASSIGN TO) : la donnee porte deja ce
rem nom et se trouve a cote du source, donc rien n'est copie.
rem Difference avec la version pod : cobol85.cmd copie au lieu de monter,
rem et refuse d'ecraser le char_input1.txt present ici. Un
rem "-i autre.txt:char_input1.txt" ne marche donc pas depuis ce dossier.
rem A lancer depuis ce dossier : les chemins sont relatifs au repertoire courant.
rem "call" : sans lui, la main ne reviendrait pas a ce script apres cobol85.cmd.
call ..\..\cobol85.cmd -i char_input1.txt inpsni1.cbl
