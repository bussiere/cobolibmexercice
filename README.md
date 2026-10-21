# cobolibmexercice

Exercices COBOL 85 (ANSI X3.23-1985 + amendement X3.23a-1989),
compilés et exécutés avec GnuCOBOL, en local ou dans un pod Podman.

## Arborescence

| Chemin                  | Contenu                                              |
|-------------------------|------------------------------------------------------|
| `cobol85.sh`            | Compile et exécute avec le `cobc` local              |
| `cobol85-podman.sh`     | Compile et exécute dans un pod Podman (GnuCOBOL)     |
| `cobol85-export.sh`     | Exporte l'image en fichier plat `.7z`                |
| `cobol85-import.sh`     | Importe un fichier plat `.7z` comme image            |
| `gnucobol85-flat.7z`    | Image GnuCOBOL exportée, prête à importer            |
| `snippet/table/`        | Snippets sur les tableaux (`OCCURS`, `SEARCH`, tri)  |
| `snippet/inputextern/`  | Snippets lisant des fichiers d'entrée externes       |
| `scripts/`              | Outils annexes (nettoyage des commentaires)          |

Les exécutables vont dans `build/`, à côté du source.

## Prérequis

- Local : GnuCOBOL (`cobc`).
- Pod : Podman. Pour import/export : `7z` (paquet `p7zip-full`).

## cobol85.sh (local)

```sh
./cobol85.sh snippet/table/tabsni11.cbl
./cobol85.sh prog.cbl arg1 arg2      # arguments passés au programme
```

## cobol85-podman.sh (pod)

```
./cobol85-podman.sh [-i source[:nom]]... fichier.cbl [args...]
./cobol85-podman.sh --clean
```

Au premier lancement, l'image `localhost/gnucobol85` est construite
(ou importée, voir plus bas). Le pod `cobol85-pod` est créé une fois,
puis réutilisé.

Options de compilation : `-x -fstack-check -std=cobol85 -fixed -Wall`.

### Exemples simples

```sh
./cobol85-podman.sh snippet/table/tabsni11.cbl
./cobol85-podman.sh prog.cbl arg1 arg2
./cobol85-podman.sh --clean          # supprime le pod et l'image
```

### Fichiers d'entrée (`-i`)

Un programme COBOL lit un fichier par son `SELECT ... ASSIGN TO` :

```cobol
SELECT CHAR-FILE ASSIGN TO "char_input.txt"
```

L'option `-i source[:nom]` fournit ce fichier au programme :

- `source` : fichier (ou dossier) sur l'hôte, chemin quelconque.
- `nom` : nom attendu par le `ASSIGN TO`. Par défaut : nom de `source`.
- Monté en lecture seule dans le répertoire courant du programme.
- Répétable : un `-i` par fichier.
- Les `-i` se placent **avant** le `.cbl`.

Exemple avec `snippet/inputextern/inpsni1.cbl` : le programme lit
`char_input.txt`, la donnée s'appelle `char_input1.txt`.

```sh
cd snippet/inputextern
../../cobol85-podman.sh -i char_input1.txt:char_input.txt inpsni1.cbl
```

Sortie :

```
=== Execution de inpsni1 (pod cobol85-pod) ===
========================================
       FICHE DE PERSONNAGE TRAVELLER
========================================
Nom         : Alexander Jamison
Carriere    : Scout
Mandats (n) : 04
UWP         : 7B6A88
Credits     : 35000      Cr
Competences : Pilot-1, Gunnery-1, Vacc Suit-1
========================================
```

Autres cas :

```sh
# Donnée ailleurs sur le disque
./cobol85-podman.sh -i ~/data/perso2.txt:char_input.txt \
    snippet/inputextern/inpsni1.cbl

# Nom déjà identique au ASSIGN TO : ":nom" inutile
./cobol85-podman.sh -i /tmp/char_input.txt snippet/inputextern/inpsni1.cbl

# Plusieurs fichiers d'entrée
./cobol85-podman.sh -i clients.txt:CLIENTS -i tarifs.dat prog.cbl

# Un dossier entier
./cobol85-podman.sh -i ./jeu-de-test:data prog.cbl   # ASSIGN TO "data/x.txt"
```

Notes :

- Si `source` est déjà dans le dossier du `.cbl` avec le bon nom,
  rien n'est monté : le fichier est déjà visible.
- Podman crée un point de montage vide sur l'hôte ; le script le
  supprime en fin d'exécution.
- Les fichiers d'entrée sont en lecture seule. Les fichiers écrits par
  le programme (`OPEN OUTPUT`) arrivent dans le dossier du `.cbl`.
- GnuCOBOL 3.1 ignore les variables `DD_xxx` si le nom contient un
  point : d'où le montage direct sous le nom attendu.

## Export / import de l'image

```sh
./cobol85-export.sh                    # -> gnucobol85-flat.7z
./cobol85-export.sh autre.7z
./cobol85-import.sh gnucobol85-flat.7z # recrée localhost/gnucobol85
```

L'import évite la reconstruction (pas de réseau nécessaire).
