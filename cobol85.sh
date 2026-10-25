#!/usr/bin/env bash
# Compile et execute un fichier COBOL en norme COBOL 85 (ANSI X3.23-1985
# + amendement X3.23a-1989 : fonctions intrinseques).
# Usage : ./cobol85.sh fichier.cbl [args du programme...]
# Necessite GnuCOBOL (cobc).
#
# Version "locale" : utilise le cobc installe sur la machine. Plus rapide
# que cobol85-podman.sh (pas de conteneur), mais le resultat depend de la
# version de GnuCOBOL et de gcc installees. Equivalent Windows : cobol85.cmd.

# -e : on s'arrete a la premiere erreur (inutile d'executer si la
#      compilation a echoue) ; -u : une variable non definie est une
#      erreur et non une chaine vide silencieuse ; -o pipefail : une
#      erreur au milieu d'un pipe (cobc --info | sed) n'est pas masquee.
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 fichier.cbl [args...]" >&2
    exit 1
fi

# On retire le source de $@ : ce qui reste est passe tel quel au programme
src="$1"; shift
if [[ ! -f "$src" ]]; then
    echo "Erreur: fichier introuvable: $src" >&2
    exit 1
fi

# Chemin absolu du dossier du source : le script marche ainsi quel que
# soit le repertoire depuis lequel on l'appelle.
src_dir="$(cd "$(dirname "$src")" && pwd)"
src_name="$(basename "$src")"
# L'executable porte le nom du source sans extension (tabsni1.cbl -> tabsni1)
exe_name="${src_name%.*}"
# build/ a cote du source plutot qu'a cote du script : chaque exercice
# garde ses binaires pres de son code, et build/ est ignore par git.
build_dir="$src_dir/build"
mkdir -p "$build_dir"

# -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989). Refuse les
#                extensions GnuCOBOL/IBM : on s'entraine sur la norme pure.
# -x : produit un executable (et non un module a appeler par CALL)
# -Wall : tous les avertissements, utile pour apprendre
# -fixed : format fixe colonnes 8-72, celui des cartes perforees et des
#          sources mainframe ; sans lui cobc pourrait accepter du format libre.
COBC_FLAGS=(-x -std=cobol85 -fixed -Wall)

# Verifie avant d'appeler cobc pour un message clair au lieu de
# "command not found" (et parce que cobc --info est utilise juste apres).
if ! command -v cobc >/dev/null 2>&1; then
    echo "Erreur: cobc (GnuCOBOL) introuvable" >&2
    exit 1
fi

# cobc genere du C puis appelle gcc avec ses propres options (COB_CFLAGS).
# gcc Ubuntu definit deja _FORTIFY_SOURCE=3 ; cobc ajoute -D_FORTIFY_SOURCE=2
# => warning "redefined" a chaque compilation, qui noie les vrais messages.
# On reprend les options de cobc (cobc --info) sans cette definition.
# Si COB_CFLAGS est deja defini par l'utilisateur, on le respecte.
export COB_CFLAGS="${COB_CFLAGS:-$(cobc --info | sed -n 's/^COB_CFLAGS *: //p' \
    | sed 's/-D_FORTIFY_SOURCE=[0-9]*//')}"

cobc "${COBC_FLAGS[@]}" -o "$build_dir/$exe_name" "$src_dir/$src_name"
echo "=== Execution de $exe_name ==="
# Le programme s'execute dans le repertoire courant de l'appelant : les
# ASSIGN TO relatifs sont donc resolus depuis la ou on lance le script.
"$build_dir/$exe_name" "$@"
