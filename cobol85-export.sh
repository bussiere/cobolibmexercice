#!/usr/bin/env bash
# Exporte le conteneur GnuCOBOL en fichier plat compresse 7z (LZMA2 max).
# "Plat" : systeme de fichiers aplati (podman export), sans couches.
# Usage : ./cobol85-export.sh [sortie.7z]
set -euo pipefail

IMAGE="localhost/gnucobol85:latest"
OUT="${1:-gnucobol85-flat.7z}"

command -v 7z >/dev/null 2>&1 || { echo "Erreur: 7z introuvable (p7zip-full)" >&2; exit 1; }

if ! podman image exists "$IMAGE"; then
    echo "Erreur: image $IMAGE absente (lancer cobol85-podman.sh d'abord)" >&2
    exit 1
fi

# Conteneur temporaire, juste pour l'export
ctr="$(podman create "$IMAGE")"
trap 'podman rm -f "$ctr" >/dev/null' EXIT

rm -f "$OUT"
# -mx=9 -mfb=273 : compression max ; -ms=on : archive solide
# -md=384m : dictionnaire plafonne (~3.3 Go RAM a la compression,
#            ~400 Mo a la decompression). Sans plafond, en lecture
#            sur stdin, 7z prendrait le dictionnaire max (~16 Go RAM).
podman export "$ctr" | 7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=384m \
    -ms=on -mmt=on -si"gnucobol85-flat.tar" "$OUT" >/dev/null
echo "Export OK: $OUT ($(du -h "$OUT" | cut -f1))"
