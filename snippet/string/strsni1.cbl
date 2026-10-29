      * SNIPPET FOR UNDERSTANDING STRING MANIPULATION IN COBOL

       IDENTIFICATION DIVISION.
       PROGRAM-ID. STRSNI1.
       AUTHOR. BUSSIERE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VARIABLES.
          05 WS-STR-ORIGINE  PIC X(30) VALUE "  COBOL   EST   GENIAL  ".
          05 WS-TAILLE       PIC 9(02).
          05 WS-STR-RESULTAT PIC X(30) VALUE SPACES.
          05 WS-IDX-SRC      PIC 9(02) VALUE 1.
          05 WS-IDX-DEST     PIC 9(02) VALUE 1.
       
       PROCEDURE DIVISION.
       000-MAIN-PROCEDURE.

      * Affichage direct de la taille définie par le PIC X
      * DISPLAY MUST START IN AREA B
           DISPLAY "Taille memoire : " FUNCTION LENGTH(WS-STR-ORIGINE)

      * Stockage dans une variable numerique si besoin
           COMPUTE WS-TAILLE = FUNCTION LENGTH(WS-STR-ORIGINE)
           DISPLAY "Taille stockee : " WS-TAILLE.

           
           DISPLAY "Chaine originale : [" WS-STR-ORIGINE "]"
           
           PERFORM 100-SUPPRIMER-ESPACES 
               VARYING WS-IDX-SRC FROM 1 BY 1 
               UNTIL WS-IDX-SRC > FUNCTION LENGTH(WS-STR-ORIGINE).
               
           DISPLAY "Chaine nettoyee  : [" WS-STR-RESULTAT "]"
           MOVE  WS-STR-RESULTAT TO WS-STR-ORIGINE.
           PERFORM  200-TRIM-SPACE.
           
           STOP RUN.

       100-SUPPRIMER-ESPACES.
           IF WS-STR-ORIGINE(WS-IDX-SRC:1) NOT = SPACE
               MOVE WS-STR-ORIGINE(WS-IDX-SRC:1) 
                 TO WS-STR-RESULTAT(WS-IDX-DEST:1)
               ADD 1 TO WS-IDX-DEST
           END-IF.


       200-TRIM-SPACE.
      * --- ÉTAPE 1 : Supprimer les espaces au début ---
      * On décale tout vers la gauche jusqu'au premier caractère non-espace
           MOVE WS-STR-ORIGINE TO WS-STR-SANS-GAUCHE
           INSPECT WS-STR-SANS-GAUCHE TALLYING WS-NB-ESPACES-FIN 
               FOR LEADING SPACES

      * --- ÉTAPE 2 : Trouver la fin du texte restant ---
      * On compte les espaces à la fin en inversant la chaîne
           MOVE 0 TO WS-NB-ESPACES-FIN
           INSPECT FUNCTION REVERSE(WS-STR-SANS-GAUCHE) 
               TALLYING WS-NB-ESPACES-FIN FOR LEADING SPACES

      * On calcule la taille réelle du texte sans les espaces de fin
           COMPUTE WS-TAILLE-UTILE = 
               FUNCTION LENGTH(WS-STR-SANS-GAUCHE) - WS-NB-ESPACES-FIN

      * --- ÉTAPE 3 : Extraction finale par modification de référence ---
           MOVE WS-STR-SANS-GAUCHE(1:WS-TAILLE-UTILE) TO WS-STR-NETTOYEE

           DISPLAY "[" WS-STR-NETTOYEE "]".
      * FINISHED 
