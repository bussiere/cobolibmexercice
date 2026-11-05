      * SNIPPET FOR UNDERSTANDING LONG STRING MANIPULATION IN COBOL

       IDENTIFICATION DIVISION.
       PROGRAM-ID. STRSNI1.
       AUTHOR. BUSSIERE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * WS pour Working Storage
       01  WS-TEXTE   PIC X(100) VALUE "Ceci 10 est le debut d un tres lon
      -    "g texte qui continue sur la ligne suivante".
       01  WS-INTEGER   PIC 9(2) VALUE 42.
       PROCEDURE DIVISION.

           DISPLAY WS-TEXTE.
           DISPLAY WS-INTEGER.
      * NOUS SOMME A 2 ET ON AVANCE DE 5
           DISPLAY WS-TEXTE(2:5).
      * NOUS SOMMES A 5 ET NOUS AVANCONS DE 2     
           DISPLAY WS-TEXTE(6:2).
           MOVE WS-TEXTE(6:2) TO WS-INTEGER.
           DISPLAY WS-INTEGER.

