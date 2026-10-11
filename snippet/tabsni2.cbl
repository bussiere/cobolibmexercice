      * SNIPPET FOR UNDERSTANDING TABLE IN COBOL 2
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TABLE-TEST2.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 INX-B PIC 9(1).
       01 TAILLE-MAX PIC 9(1) VALUE 3.
       01 TABLE-NAME.
          05 TABLE-ELEMENT OCCURS 3 TIMES INDEXED BY INX-A PIC X(03)  
          VALUE "ABC".

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.


           *> Modification du 2ème élément
           MOVE "DEF" TO TABLE-ELEMENT (2).
           MOVE "GHI" TO TABLE-ELEMENT (3).

           *> Affichage pour vérifier le résultat
           DISPLAY TABLE-ELEMENT(1) " " TABLE-ELEMENT(2) " " 
           TABLE-ELEMENT(3).
           SET INX-A TO TAILLE-MAX.
           DISPLAY INX-A.
           SET INX-B TO INX-A.
           PERFORM VARYING INX-A FROM 1 BY 1 UNTIL INX-A > INX-B
            DISPLAY INX-A
            DISPLAY TABLE-ELEMENT (INX-A)
           END-PERFORM.
      * DECREASE ORDER OF BROWSING THE TABLE
           PERFORM VARYING INX-A FROM INX-B BY -1 UNTIL INX-A < 1
            DISPLAY INX-A
            DISPLAY TABLE-ELEMENT (INX-A)
           END-PERFORM.

           STOP RUN.
