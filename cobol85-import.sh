#!/usr/bin/env bash
# Importe un fichier plat compresse 7z comme image GnuCOBOL.
# Usage : ./cobol85-import.sh fichier.7z
set -euo pipefail

IMAGE="localhost/gnucobol85:latest"

if [[ $# -ne 1 || ! -f "$1" ]]; then
    echo "Usage: $0 fichier.7z" >&2
    exit 1
fi

command -v 7z >/dev/null 2>&1 || { echo "Erreur: 7z introuvable (p7zip-full)" >&2; exit 1; }

# Verifie l'archive avant import
7z t "$1" >/dev/null || { echo "Erreur: archive corrompue: $1" >&2; exit 1; }

# L'export plat perd les metadonnees : on les remet
7z x -so "$1" | podman import -q \
    --change 'WORKDIR /src' \
    --change 'ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    --change 'CMD ["/bin/bash"]' \
    - "$IMAGE" >/dev/null

echo "Import OK: $IMAGE"
podman run --rm "$IMAGE" cobc --version | head -1
