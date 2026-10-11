#!/usr/bin/env bash
# Compile et execute un fichier COBOL en norme COBOL 85 (ANSI X3.23-1985
# + amendement X3.23a-1989 : fonctions intrinseques).
# Usage : ./cobol85.sh fichier.cbl [args du programme...]
# Necessite GnuCOBOL (cobc).
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 fichier.cbl [args...]" >&2
    exit 1
fi

src="$1"; shift
if [[ ! -f "$src" ]]; then
    echo "Erreur: fichier introuvable: $src" >&2
    exit 1
fi

src_dir="$(cd "$(dirname "$src")" && pwd)"
src_name="$(basename "$src")"
exe_name="${src_name%.*}"
build_dir="$src_dir/build"
mkdir -p "$build_dir"

# -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989)
# -x : executable ; -Wall : avertissements ; -fixed : format fixe colonnes 8-72
COBC_FLAGS=(-x -std=cobol85 -fixed -Wall)

if ! command -v cobc >/dev/null 2>&1; then
    echo "Erreur: cobc (GnuCOBOL) introuvable" >&2
    exit 1
fi

# gcc Ubuntu definit deja _FORTIFY_SOURCE=3 ; cobc ajoute -D_FORTIFY_SOURCE=2
# => warning "redefined". On retire la definition de cobc.
export COB_CFLAGS="${COB_CFLAGS:-$(cobc --info | sed -n 's/^COB_CFLAGS *: //p' \
    | sed 's/-D_FORTIFY_SOURCE=[0-9]*//')}"

cobc "${COBC_FLAGS[@]}" -o "$build_dir/$exe_name" "$src_dir/$src_name"
echo "=== Execution de $exe_name ==="
"$build_dir/$exe_name" "$@"
