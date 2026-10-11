      * SNIPPET FOR UNDERSTANDING TABLE IN COBOL
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TABLE-TEST1.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 NUMBER-VALUES.
          05 FILLER PIC X(05) VALUE "One  ".
          05 FILLER PIC X(05) VALUE "Two  ".
          05 FILLER PIC X(05) VALUE "Three".
          05 FILLER PIC X(05) VALUE "Four ".
          05 FILLER PIC X(05) VALUE "Five ".
          05 FILLER PIC X(05) VALUE "Six  ".
          05 FILLER PIC X(05) VALUE "Seven".
          05 FILLER PIC X(05) VALUE "Eight".
          05 FILLER PIC X(05) VALUE "Nine ".
          05 FILLER PIC X(05) VALUE "Ten  ".

       01 NUMBER-TABLES REDEFINES NUMBER-VALUES.
      * On crée un groupe pour le premier tableau
          05 GROUP-NUMBER-1.
             10 WS-NUMBER-1 PIC X(05) OCCURS 5 TIMES.
          
      * On crée un groupe pour le deuxième tableau
          05 GROUP-NUMBER-2.
             10 WS-NUMBER-2 PIC X(05) OCCURS 5 TIMES.

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.


      * Affichage pour vérifier le résultat
           DISPLAY WS-NUMBER-1(3).
           INITIALIZE NUMBER-TABLES REPLACING ALPHANUMERIC DATA 
           BY "XXXXX".
           DISPLAY " FIRST TEST ".
           DISPLAY WS-NUMBER-1(3).
           DISPLAY WS-NUMBER-2(3).
           DISPLAY " SECOND TEST ".
           INITIALIZE GROUP-NUMBER-2 REPLACING ALPHANUMERIC DATA 
           BY "YYYYY".
           DISPLAY WS-NUMBER-1(3).
           DISPLAY WS-NUMBER-2(3).
           STOP RUN.
