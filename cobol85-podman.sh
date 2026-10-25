#!/usr/bin/env bash
# Compile et execute un fichier COBOL en norme COBOL 85 (ANSI X3.23-1985
# + amendement X3.23a-1989) dans un pod Podman avec GnuCOBOL.
# Usage : ./cobol85-podman.sh [-i source[:nom]]... fichier.cbl [args...]
#         ./cobol85-podman.sh --clean   (supprime le pod et l'image)
# -i : fichier (ou dossier) d'entree, repetable. Monte en lecture seule
#      dans le repertoire courant du programme sous "nom" (defaut : nom
#      de la source), soit le nom du ASSIGN TO du SELECT COBOL.
#      Les options -i se placent avant fichier.cbl.
#      Ex : ./cobol85-podman.sh -i char_input1.txt:char_input.txt inpsni1.cbl
#           ./cobol85-podman.sh -i a.txt -i b.dat:CLIENTS prog.cbl
#      Note : GnuCOBOL 3.1 ignore les variables DD_xxx si le nom contient
#      un point, d'ou le montage direct sous le nom attendu.
#
# Pourquoi un conteneur : la meme version de GnuCOBOL partout, sans rien
# installer sur la machine, et une image exportable (cobol85-export.sh)
# pour un poste sans reseau.

# -e : arret a la premiere erreur ; -u : variable non definie = erreur ;
# -o pipefail : une erreur dans un pipe n'est pas masquee.
set -euo pipefail

# localhost/ : image construite ici, jamais tiree d'un registre. Le nom
# est partage avec cobol85-export.sh et cobol85-import.sh.
IMAGE="localhost/gnucobol85:latest"
POD="cobol85-pod"

# --clean avant tout le reste : on veut pouvoir nettoyer meme sans .cbl.
# Utile pour forcer la reconstruction de l'image (nouvelle version de
# Debian ou de GnuCOBOL). "|| true" : ne pas echouer si deja absent.
if [[ "${1:-}" == "--clean" ]]; then
    podman pod rm -f "$POD" >/dev/null 2>&1 || true
    podman rmi -f "$IMAGE" >/dev/null 2>&1 || true
    echo "Pod $POD et image $IMAGE supprimes."
    exit 0
fi

usage() {
    echo "Usage: $0 [-i source[:nom]]... fichier.cbl [args...] | --clean" >&2
    exit 1
}

# Lecture des options du script. On s'arrete au premier argument qui
# n'est pas une option (le .cbl) : tout ce qui suit appartient au
# programme COBOL, meme s'il commence par "-". "--" force cet arret.
inputs=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) [[ $# -ge 2 ]] || usage; inputs+=("$2"); shift 2 ;;
        --) shift; break ;;
        -*) usage ;;
        *) break ;;
    esac
done
[[ $# -ge 1 ]] || usage

src="$1"; shift
if [[ ! -f "$src" ]]; then
    echo "Erreur: fichier introuvable: $src" >&2
    exit 1
fi

# Chemin absolu : podman -v exige des chemins absolus cote hote
src_dir="$(cd "$(dirname "$src")" && pwd)"
src_name="$(basename "$src")"
exe_name="${src_name%.*}"
# Cree cote hote : le dossier du source est monte dans le conteneur, donc
# l'executable produit dans /src/build reste disponible apres coup.
mkdir -p "$src_dir/build"

# Image GnuCOBOL (construite une seule fois)
# La construction prend du temps et du reseau : on ne la refait que si
# l'image manque (premier lancement, --clean, ou pas d'import 7z).
# Dockerfile en heredoc : le script reste autonome, un seul fichier.
# bookworm-slim : Debian stable, petite, et son paquet gnucobol suffit.
# --no-install-recommends et rm des listes apt : image plus legere, donc
# export 7z plus petit.
if ! podman image exists "$IMAGE"; then
    echo "Construction de l'image $IMAGE..." >&2
    podman build -q -t "$IMAGE" -f - . >/dev/null <<'EOF'
FROM docker.io/library/debian:bookworm-slim
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y --no-install-recommends gnucobol \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
EOF
fi

# Pod (cree une seule fois, garde entre les executions)
# keep-id : les fichiers generes appartiennent a l'utilisateur courant
# Sans keep-id, en rootless, build/ serait cree par un uid decale et
# l'utilisateur ne pourrait plus le supprimer sans "podman unshare".
# Le pod porte cette option une fois pour toutes les executions.
if ! podman pod exists "$POD"; then
    podman pod create --name "$POD" --userns=keep-id >/dev/null
fi

# Fichiers d'entree : montes en lecture seule dans /src/<nom>
# Pourquoi monter plutot que copier : la source n'est ni dupliquee ni
# modifiable par le programme (ro), et rien ne reste apres l'execution.
input_mounts=()
placeholders=()
for spec in "${inputs[@]}"; do
    # "source:nom" -> coupe sur le premier ":" ; sans ":" le nom est
    # celui de la source (cas ou il correspond deja au ASSIGN TO).
    in_src="${spec%%:*}"
    in_name="${spec#*:}"
    [[ "$spec" == *:* ]] || in_name="$(basename "$in_src")"
    if [[ ! -e "$in_src" ]]; then
        echo "Erreur: entree introuvable: $in_src" >&2
        exit 1
    fi
    # Le nom doit rester dans /src : un "/" ou ".." ferait monter le
    # fichier ailleurs, un nom cache (.x) est surement une erreur.
    if [[ "$in_name" == */* || "$in_name" == .* ]]; then
        echo "Erreur: nom d'entree invalide: $in_name" >&2
        exit 1
    fi
    in_abs="$(cd "$(dirname "$in_src")" && pwd)/$(basename "$in_src")"
    # Source deja a sa place : rien a monter
    # (elle est deja visible via le montage du dossier du source ; la
    # monter une seconde fois sur elle-meme serait inutile).
    [[ "$in_abs" == "$src_dir/$in_name" ]] && continue
    # Podman cree le point de montage sur l'hote : on le retire apres
    # On ne note que les chemins qui n'existaient pas avant, pour ne
    # jamais supprimer un fichier de l'utilisateur.
    [[ -e "$src_dir/$in_name" ]] || placeholders+=("$src_dir/$in_name")
    # :z (minuscule) = label SELinux partage, car le fichier peut etre
    # monte par plusieurs conteneurs ; :Z serait prive au conteneur.
    input_mounts+=(-v "$in_abs:/src/$in_name:ro,z")
done

# Supprime les points de montage vides laisses par Podman.
# Prudence : rmdir n'efface qu'un dossier vide, et un fichier n'est
# supprime que s'il est vide (-s), donc jamais une vraie donnee.
cleanup() {
    local p
    for p in "${placeholders[@]}"; do
        if [[ -d "$p" ]]; then rmdir "$p" 2>/dev/null || true
        elif [[ -f "$p" && ! -s "$p" ]]; then rm -f "$p"; fi
    done
}
# EXIT : nettoyage aussi en cas d'erreur de compilation ou de Ctrl+C
trap cleanup EXIT

# Lance une commande dans un conteneur ephemere (--rm) rattache au pod.
# Le dossier du source est monte en /src (:Z = label SELinux prive) et
# sert de repertoire courant : les ASSIGN TO relatifs y sont resolus.
# Les montages -i, plus profonds (/src/<nom>), se superposent a /src.
run_in_pod() {
    podman run --rm --pod "$POD" -v "$src_dir:/src:Z" "${input_mounts[@]}" \
        -w /src "$IMAGE" "$@"
}

# -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989)
# -x : executable ; -fixed : format fixe colonnes 8-72 ; -Wall : avertissements
# -fstack-check : controle de la pile d'appels (PERFORM/CALL) a l'execution ;
#                 une recursion non voulue donne un message clair plutot
#                 qu'un plantage obscur.
# Compilation et execution dans deux conteneurs : chaque etape repart
# d'un etat propre, et seul build/ fait le lien entre les deux.
run_in_pod cobc -x -fstack-check -std=cobol85 -fixed -Wall -o "build/$exe_name" "$src_name"
echo "=== Execution de $exe_name (pod $POD) ==="
run_in_pod "./build/$exe_name" "$@"
