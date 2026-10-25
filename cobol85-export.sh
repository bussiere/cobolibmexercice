#!/usr/bin/env bash
# Exporte le conteneur GnuCOBOL en fichier plat compresse 7z (LZMA2 max).
# "Plat" : systeme de fichiers aplati (podman export), sans couches.
# Usage : ./cobol85-export.sh [sortie.7z]
#
# Pourquoi : transporter l'environnement sur une machine sans reseau (ou
# sans acces a docker.io) et eviter la reconstruction. Pourquoi "plat"
# plutot que "podman save" : une seule couche, sans l'historique de
# construction ni les doublons entre couches, donc une archive plus
# petite. Contrepartie : les metadonnees (WORKDIR, ENV, CMD) sont
# perdues, cobol85-import.sh les remet.

# -e : arret a la premiere erreur ; -u : variable non definie = erreur ;
# -o pipefail : indispensable ici, sinon un echec de podman export dans
# le pipe serait masque par le succes de 7z (archive vide ou tronquee).
set -euo pipefail

# Meme nom d'image que cobol85-podman.sh et cobol85-import.sh
IMAGE="localhost/gnucobol85:latest"
OUT="${1:-gnucobol85-flat.7z}"

# Verifications en amont : mieux vaut un message clair qu'un pipe qui
# echoue a moitie.
command -v 7z >/dev/null 2>&1 || { echo "Erreur: 7z introuvable (p7zip-full)" >&2; exit 1; }

if ! podman image exists "$IMAGE"; then
    echo "Erreur: image $IMAGE absente (lancer cobol85-podman.sh d'abord)" >&2
    exit 1
fi

# Conteneur temporaire, juste pour l'export
# podman export travaille sur un conteneur, pas sur une image : on en
# cree un sans le demarrer. Le trap le supprime meme si l'export echoue.
ctr="$(podman create "$IMAGE")"
trap 'podman rm -f "$ctr" >/dev/null' EXIT

# 7z a ajouterait le tar a une archive existante au lieu de la remplacer
rm -f "$OUT"
# -mx=9 -mfb=273 : compression max ; -ms=on : archive solide
# -md=384m : dictionnaire plafonne (~3.3 Go RAM a la compression,
#            ~400 Mo a la decompression). Sans plafond, en lecture
#            sur stdin, 7z prendrait le dictionnaire max (~16 Go RAM).
# -mmt=on : compression multi-thread, sinon tres lente au niveau 9.
# -si : lit le tar sur stdin, nomme "gnucobol85-flat.tar" dans l'archive.
#       Pas de fichier tar intermediaire sur disque (plusieurs centaines
#       de Mo economises).
podman export "$ctr" | 7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=384m \
    -ms=on -mmt=on -si"gnucobol85-flat.tar" "$OUT" >/dev/null
echo "Export OK: $OUT ($(du -h "$OUT" | cut -f1))"
