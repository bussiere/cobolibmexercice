# cobolibmexercice

Exercices COBOL 85 (ANSI X3.23-1985 + amendement X3.23a-1989),
compilés et exécutés avec GnuCOBOL, en local ou dans un pod Podman.

## Arborescence

| Chemin                  | Contenu                                              |
|-------------------------|------------------------------------------------------|
| `cobol85.sh`            | Compile et exécute avec le `cobc` local              |
| `cobol85.cmd`           | Idem sous Windows (cmd), avec `-i`                   |
| `cobol85-fixenv.cmd`    | Configure l'environnement GnuCOBOL sous Windows      |
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
- Windows : GnuCOBOL pour Windows (build MinGW), dans le `PATH` ou
  installé à un emplacement habituel (voir `cobol85-fixenv.cmd`).
- Pod : Podman. Pour import/export : `7z` (paquet `p7zip-full`).

## cobol85.sh (local)

```sh
./cobol85.sh snippet/table/tabsni11.cbl
./cobol85.sh prog.cbl arg1 arg2      # arguments passés au programme
```

## cobol85.cmd (Windows)

Même rôle que `cobol85.sh`, pour GnuCOBOL installé sous Windows.
Accepte aussi `-i source[:nom]` comme `cobol85-podman.sh` :

```bat
cobol85.cmd snippet\table\tabsni11.cbl
cobol85.cmd prog.cbl arg1 arg2
cobol85.cmd -i C:\data\clients.txt:CLIENTS prog.cbl
cd snippet\inputextern
..\..\cobol85.cmd -i char_input1.txt inpsni1.cbl   :: = build_run.cmd
```

Différences avec la version pod :

- Pas de montage : l'entrée est **copiée** dans le dossier du `.cbl`
  sous `nom`, puis supprimée en fin d'exécution.
- Si un fichier `nom` existe déjà à cet endroit (autre que la source),
  le script refuse plutôt que de l'écraser.
- Le programme s'exécute dans le dossier du `.cbl`.
- Exécutable : `build\<nom>.exe`.

Conséquence pour `snippet\inputextern` : `char_input1.txt` est déjà à
côté des `.cbl`, donc `-i autre.txt:char_input1.txt` y est refusé.
Pour essayer une autre donnée, copier le `.cbl` dans un autre dossier
(ou utiliser la version pod, qui masque le fichier sans l'écraser).

### Environnement GnuCOBOL (`cobol85-fixenv.cmd`)

Le `cobc` MinGW cherche sa configuration dans son chemin de compilation
(`/mingw/...`) si `COB_CONFIG_DIR` n'est pas défini, d'où l'erreur :

```
configuration error:
/mingw/share/gnucobol/config\cobol85.conf: No such file or directory
```

`cobol85.cmd` appelle donc `cobol85-fixenv.cmd` quand `COB_CONFIG_DIR`
est absent : inutile de lancer `set_env.cmd` à la main. Le script
retrouve l'installation (dossier donné en argument, sinon `cobc` du
`PATH`, sinon `C:\GnuCOBOL`, `%ProgramFiles%\GnuCOBOL`...) et définit
les variables `COB_*`. Utilisable seul :

```bat
cobol85-fixenv.cmd                       :: fenêtre courante seulement
cobol85-fixenv.cmd C:\GnuCOBOL           :: dossier explicite
cobol85-fixenv.cmd C:\GnuCOBOL /persist  :: + prochaines fenêtres (setx)
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
SELECT CHAR-FILE ASSIGN TO "char_input1.txt"
```

L'option `-i source[:nom]` fournit ce fichier au programme :

- `source` : fichier (ou dossier) sur l'hôte, chemin quelconque.
- `nom` : nom attendu par le `ASSIGN TO`. Par défaut : nom de `source`.
- Monté en lecture seule dans le répertoire courant du programme.
- Répétable : un `-i` par fichier.
- Les `-i` se placent **avant** le `.cbl`.

Exemple avec `snippet/inputextern/inpsni1.cbl` : le programme lit
`char_input1.txt`, la donnée porte déjà ce nom (c'est `build_run.sh`).

```sh
cd snippet/inputextern
../../cobol85-podman.sh -i char_input1.txt inpsni1.cbl
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
# (masque le char_input1.txt du dossier le temps de l'exécution)
./cobol85-podman.sh -i ~/data/perso2.txt:char_input1.txt \
    snippet/inputextern/inpsni1.cbl

# Nom déjà identique au ASSIGN TO : ":nom" inutile
./cobol85-podman.sh -i /tmp/char_input1.txt snippet/inputextern/inpsni1.cbl

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
