#!/usr/bin/env bash
# script surtout present pour se rappeler la syntaxe
# inpsni1.cbl lit "char_input1.txt" (ASSIGN TO) : la donnee porte deja ce
# nom et se trouve a cote du source, donc pas besoin de ":nom" et rien
# n'est monte en plus. Pour tester une autre donnee sans toucher au .cbl :
#   ../../cobol85-podman.sh -i autre_perso.txt:char_input1.txt inpsni1.cbl
# A lancer depuis ce dossier : les chemins sont relatifs au repertoire courant.
../../cobol85-podman.sh -i char_input1.txt inpsni1.cbl
