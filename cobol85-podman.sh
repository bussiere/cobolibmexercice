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
set -euo pipefail

IMAGE="localhost/gnucobol85:latest"
POD="cobol85-pod"

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

src_dir="$(cd "$(dirname "$src")" && pwd)"
src_name="$(basename "$src")"
exe_name="${src_name%.*}"
mkdir -p "$src_dir/build"

# Image GnuCOBOL (construite une seule fois)
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
if ! podman pod exists "$POD"; then
    podman pod create --name "$POD" --userns=keep-id >/dev/null
fi

# Fichiers d'entree : montes en lecture seule dans /src/<nom>
input_mounts=()
placeholders=()
for spec in "${inputs[@]}"; do
    in_src="${spec%%:*}"
    in_name="${spec#*:}"
    [[ "$spec" == *:* ]] || in_name="$(basename "$in_src")"
    if [[ ! -e "$in_src" ]]; then
        echo "Erreur: entree introuvable: $in_src" >&2
        exit 1
    fi
    if [[ "$in_name" == */* || "$in_name" == .* ]]; then
        echo "Erreur: nom d'entree invalide: $in_name" >&2
        exit 1
    fi
    in_abs="$(cd "$(dirname "$in_src")" && pwd)/$(basename "$in_src")"
    # Source deja a sa place : rien a monter
    [[ "$in_abs" == "$src_dir/$in_name" ]] && continue
    # Podman cree le point de montage sur l'hote : on le retire apres
    [[ -e "$src_dir/$in_name" ]] || placeholders+=("$src_dir/$in_name")
    input_mounts+=(-v "$in_abs:/src/$in_name:ro,z")
done

cleanup() {
    local p
    for p in "${placeholders[@]}"; do
        if [[ -d "$p" ]]; then rmdir "$p" 2>/dev/null || true
        elif [[ -f "$p" && ! -s "$p" ]]; then rm -f "$p"; fi
    done
}
trap cleanup EXIT

run_in_pod() {
    podman run --rm --pod "$POD" -v "$src_dir:/src:Z" "${input_mounts[@]}" \
        -w /src "$IMAGE" "$@"
}

# -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989)
# -x : executable ; -fixed : format fixe colonnes 8-72 ; -Wall : avertissements
run_in_pod cobc -x -fstack-check -std=cobol85 -fixed -Wall -o "build/$exe_name" "$src_name"
echo "=== Execution de $exe_name (pod $POD) ==="
run_in_pod "./build/$exe_name" "$@"
