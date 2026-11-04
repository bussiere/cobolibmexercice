      * SNIPPET FOR UNDERSTANDING LONG STRING MANIPULATION IN COBOL

       IDENTIFICATION DIVISION.
       PROGRAM-ID. STRSNI2.
       AUTHOR. BUSSIERE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * WS pour Working Storage
       01  WS-TEXTE   PIC X(100) VALUE "Ceci est le debut d un tres lon
      -    "g texte qui continue sur la ligne suivante".
       PROCEDURE DIVISION.

           DISPLAY WS-TEXTE.
