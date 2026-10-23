      * SNIPPET FOR UNDERSTANDING INPUT DATA / FILE IN COBOL
      * NOW SPLITTING AND EXTRACTING DATA
      * SKILLS AND CARACS
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRAVELLER-SHEET.
       AUTHOR. BUSSIERE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CHAR-FILE ASSIGN TO "char_input1.txt"
      * Lecture ligne par ligne du fichier
           ORGANIZATION IS LINE SEQUENTIAL
      * Lecture du debut a la fin
           ACCESS MODE IS SEQUENTIAL
      * Demande au système d'exploitation de renvoyer 
      * un code à deux caractères dans la variable WS-FS
      * 00 : Succès total
      * 10 : Fin de fichier (EOF).
      * 35 : Fichier introuvable.
      * 39 : Conflit d'attributs. Le fichier existe, mais sa structure 
      * réelle ne correspond pas 
      * 42 : Fichier déjà ouvert.
           FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       FD  CHAR-FILE.
       01  CHAR-RECORD         PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-FS               PIC XX.
       01  WS-EOF              PIC X           VALUE "N".
           88  EOF-REACHED                     VALUE "Y".

       01  WS-COUNTER          PIC 9(2)        VALUE 1.

      * --- NOUVELLES VARIABLES POUR LE SPLIT ---
      * Pointeur pour indiquer où commencer la lecture dans la chaîne
       01  WS-POINTER          PIC 9(3)        VALUE 1.
      * Compteur du nombre réel de compétences extraites
       01  WS-SKILL-COUNT      PIC 9(2)        VALUE 0.
      * Tableau fixe pour stocker jusqu'à 5 compétences
       01  WS-SKILLS-TABLE.
           05 WS-SKILL-ITEM    PIC X(20) OCCURS 5 TIMES.
      * Index pour la boucle d'affichage
       01  WS-IDX              PIC 9(2).

      * Structure de la fiche stockee en memoire
       01  CHARACTER-SHEET.
           05 CHAR-NAME        PIC X(30).
           05 CHAR-CLASS       PIC X(20).
           05 CHAR-TERMS       PIC X(02).
           05 CHAR-UWP         PIC X(06).
           05 CHAR-CREDITS     PIC X(10).
           05 CHAR-SKILLS      PIC X(50).

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           OPEN INPUT CHAR-FILE
           IF WS-FS NOT = "00"
               DISPLAY "ERREUR OUVERTURE FICHIER. STATUS: " WS-FS
               STOP RUN
           END-IF

           PERFORM UNTIL EOF-REACHED
               READ CHAR-FILE
                   AT END
                       SET EOF-REACHED TO TRUE
                   NOT AT END
                       PERFORM PROCESS-LINE
               END-READ
           END-PERFORM

           CLOSE CHAR-FILE
           PERFORM DISPLAY-SHEET
           STOP RUN.

        PROCESS-LINE.
           EVALUATE WS-COUNTER
               WHEN 1 MOVE CHAR-RECORD TO CHAR-NAME
               WHEN 2 MOVE CHAR-RECORD TO CHAR-CLASS
               WHEN 3 MOVE CHAR-RECORD TO CHAR-TERMS
               WHEN 4 MOVE CHAR-RECORD TO CHAR-UWP
               WHEN 5 MOVE CHAR-RECORD TO CHAR-CREDITS
               WHEN 6 
                   MOVE CHAR-RECORD TO CHAR-SKILLS
                   PERFORM SPLIT-SKILLS
           END-EVALUATE
           ADD 1 TO WS-COUNTER.

       SPLIT-SKILLS.
      * Initialisation du pointeur au début de la chaîne de caractères
           MOVE 1 TO WS-POINTER
           
      * Découpage de la chaîne CHAR-SKILLS par les virgules
           UNSTRING CHAR-SKILLS DELIMITED BY ","
               INTO WS-SKILL-ITEM(1)
                    WS-SKILL-ITEM(2)
                    WS-SKILL-ITEM(3)
                    WS-SKILL-ITEM(4)
                    WS-SKILL-ITEM(5)
               WITH POINTER WS-POINTER
               TALLYING IN WS-SKILL-COUNT
           END-UNSTRING.


       DISPLAY-SHEET.
           DISPLAY "========================================"
           DISPLAY "       FICHE DE PERSONNAGE TRAVELLER    "
           DISPLAY "========================================"
           DISPLAY "Nom         : " CHAR-NAME
           DISPLAY "Carriere    : " CHAR-CLASS
           DISPLAY "Mandats (n) : " CHAR-TERMS
           DISPLAY "UWP         : " CHAR-UWP
           DISPLAY "Credits     : " CHAR-CREDITS " Cr"
           DISPLAY "----------------------------------------"
           DISPLAY "Liste des Competences splitees :"
           
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 5
               IF WS-SKILL-ITEM(WS-IDX) NOT = SPACES
                   DISPLAY "  - " WS-SKILL-ITEM(WS-IDX)
               END-IF
           END-PERFORM
           DISPLAY "========================================".

