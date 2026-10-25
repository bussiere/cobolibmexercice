#!/usr/bin/env bash
# Importe un fichier plat compresse 7z comme image GnuCOBOL.
# Usage : ./cobol85-import.sh fichier.7z
#
# Pendant de cobol85-export.sh : recree l'image sans reseau ni
# reconstruction. Ensuite cobol85-podman.sh la trouve et ne construit rien.

# -e : arret a la premiere erreur ; -u : variable non definie = erreur ;
# -o pipefail : un echec de 7z dans le pipe ne doit pas laisser podman
# importer une image tronquee en silence.
set -euo pipefail

# Meme nom que dans cobol85-podman.sh : c'est ce qui fait que l'image
# importee est reutilisee au lieu d'etre reconstruite.
IMAGE="localhost/gnucobol85:latest"

if [[ $# -ne 1 || ! -f "$1" ]]; then
    echo "Usage: $0 fichier.7z" >&2
    exit 1
fi

command -v 7z >/dev/null 2>&1 || { echo "Erreur: 7z introuvable (p7zip-full)" >&2; exit 1; }

# Verifie l'archive avant import
# Une archive corrompue (copie incomplete, cle USB) planterait au milieu
# du flux ; mieux vaut le savoir avant de toucher a l'image existante.
7z t "$1" >/dev/null || { echo "Erreur: archive corrompue: $1" >&2; exit 1; }

# L'export plat perd les metadonnees : on les remet
# Memes valeurs que l'image construite par cobol85-podman.sh :
# - WORKDIR /src : repertoire ou le script monte les sources ;
# - ENV PATH : sans lui, "cobc" ne serait pas trouve dans le conteneur
#   (l'image importee n'a aucune variable d'environnement) ;
# - CMD bash : pour "podman run -it" a la main, comme l'image Debian.
# 7z x -so decompresse vers stdout : pas de tar temporaire sur disque.
7z x -so "$1" | podman import -q \
    --change 'WORKDIR /src' \
    --change 'ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    --change 'CMD ["/bin/bash"]' \
    - "$IMAGE" >/dev/null

echo "Import OK: $IMAGE"
# Test de fumee : prouve que l'image demarre et que cobc fonctionne
podman run --rm "$IMAGE" cobc --version | head -1
