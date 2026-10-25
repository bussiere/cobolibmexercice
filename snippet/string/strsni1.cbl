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
           
           STOP RUN.

       100-SUPPRIMER-ESPACES.
           IF WS-STR-ORIGINE(WS-IDX-SRC:1) NOT = SPACE
               MOVE WS-STR-ORIGINE(WS-IDX-SRC:1) 
                 TO WS-STR-RESULTAT(WS-IDX-DEST:1)
               ADD 1 TO WS-IDX-DEST
           END-IF.
      
      * FINISHED 
