      * SNIPPET FOR UNDERSTANDING TABLE IN COBOL
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TABLE-TEST1.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 TABLE-NAME.
          05 TABLE-ELEMENT OCCURS 3 TIMES PIC X(03)  VALUE "ABC".

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.


      *> Modification du 2ème élément
           MOVE "DEF" TO TABLE-ELEMENT (2).

      *> Affichage pour vérifier le résultat
           DISPLAY TABLE-ELEMENT(1) " " TABLE-ELEMENT(2) " ".
           DISPLAY TABLE-ELEMENT(3).

           STOP RUN.
