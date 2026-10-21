      * SNIPPET FOR UNDERSTANDING INPUT DATA / FILE IN COBOL

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
      * Assigne la ligne lue au bon champ selon le compteur de ligne
           EVALUATE WS-COUNTER
               WHEN 1 MOVE CHAR-RECORD TO CHAR-NAME
               WHEN 2 MOVE CHAR-RECORD TO CHAR-CLASS
               WHEN 3 MOVE CHAR-RECORD TO CHAR-TERMS
               WHEN 4 MOVE CHAR-RECORD TO CHAR-UWP
               WHEN 5 MOVE CHAR-RECORD TO CHAR-CREDITS
               WHEN 6 MOVE CHAR-RECORD TO CHAR-SKILLS
           END-EVALUATE
           ADD 1 TO WS-COUNTER.

       DISPLAY-SHEET.
           DISPLAY "========================================"
           DISPLAY "       FICHE DE PERSONNAGE TRAVELLER    "
           DISPLAY "========================================"
           DISPLAY "Nom         : " CHAR-NAME
           DISPLAY "Carriere    : " CHAR-CLASS
           DISPLAY "Mandats (n) : " CHAR-TERMS
           DISPLAY "UWP         : " CHAR-UWP
           DISPLAY "Credits     : " CHAR-CREDITS " Cr"
           DISPLAY "Competences : " CHAR-SKILLS
           DISPLAY "========================================".
