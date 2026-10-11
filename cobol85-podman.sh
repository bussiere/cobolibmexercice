#!/usr/bin/env bash
# Compile et execute un fichier COBOL en norme COBOL 85 (ANSI X3.23-1985
# + amendement X3.23a-1989) dans un pod Podman avec GnuCOBOL.
# Usage : ./cobol85-podman.sh fichier.cbl [args du programme...]
#         ./cobol85-podman.sh --clean   (supprime le pod et l'image)
set -euo pipefail

IMAGE="localhost/gnucobol85:latest"
POD="cobol85-pod"

if [[ "${1:-}" == "--clean" ]]; then
    podman pod rm -f "$POD" 2>/dev/null || true
    podman rmi -f "$IMAGE" 2>/dev/null || true
    echo "Pod $POD et image $IMAGE supprimes."
    exit 0
fi

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 fichier.cbl [args...] | --clean" >&2
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

run_in_pod() {
    podman run --rm --pod "$POD" -v "$src_dir:/src:Z" -w /src "$IMAGE" "$@"
}

# -std=cobol85 : dialecte COBOL 85 (inclut l'amendement 1989)
# -x : executable ; -fixed : format fixe colonnes 8-72 ; -Wall : avertissements
run_in_pod cobc -x -std=cobol85 -fixed -Wall -o "build/$exe_name" "$src_name"
echo "=== Execution de $exe_name (pod $POD) ==="
run_in_pod "./build/$exe_name" "$@"
