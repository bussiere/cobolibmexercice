      * SNIPPET FOR UNDERSTANDING TABLE IN COBOL
      * BINARY SEARCH IN COBOL
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TABLE-TEST8.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * LE NIVEAU 77 IDENTIFIE LES ENTREES DE DESCRIPTION D'ELEMENTS 
      * DE DONNEES QUI SONT DES ELEMENTS INDEPENDANTS 
       77 PEOPLE-SEARCH-DATA     PIC X(20).
       01 PEOPLE-SERIAL.
           05 PEOPLE-NAME OCCURS 50 TIMES
           ASCENDING KEY IS PEOPLE-NAME
           INDEXED BY PL-IDX PIC X(20).

      * Variables de travail pour le tri
       01  WS-VARIABLES-TRI.
           05 WS-TEMP-NOM         PIC X(30).
           05 WS-MAX-ELEMENTS     PIC 9(02) VALUE 10.
           05 WS-I                PIC 9(02).
           05 WS-J                PIC 9(02).
           05 WS-J-PLUS-1         PIC 9(02).
           05 WS-SWAP-FLAG        PIC X(01).
              88 TABLEAU-TRIE     VALUE 'O'.
              88 PAS-ENCORE-TRIE  VALUE 'N'.
         
       PROCEDURE DIVISION.
      * MOVE EST INUTILE NOUS ALLON TRIER LES DONNEES
      *    MOVE HIGH-VALUES TO PEOPLE-SERIAL.
      
      
      * MOVE POUR LES DONNEES
           MOVE "TITI" TO PEOPLE-NAME(1).
           MOVE "TOTO" TO PEOPLE-NAME(2).
           MOVE  "TOTO" TO PEOPLE-SEARCH-DATA.
      * ON APPEL ICI L OPERATION DE TRIAGE DE TABLEAU
           PERFORM TRIER-TABLEAU.

           SEARCH ALL PEOPLE-NAME
           AT END DISPLAY "Not found"
           WHEN PEOPLE-SEARCH-DATA = PEOPLE-NAME(PL-IDX)
           DISPLAY "Found"
           DISPLAY "INDEX :"
           DISPLAY PL-IDX
           DISPLAY "NOM :"
           DISPLAY PEOPLE-SEARCH-DATA
           DISPLAY  PEOPLE-NAME(PL-IDX).
           STOP RUN.

       TRIER-TABLEAU.
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > WS-MAX-ELEMENTS - 1
               
               SET TABLEAU-TRIE TO TRUE
               
               PERFORM VARYING WS-J FROM 1 BY 1 
                       UNTIL WS-J > WS-MAX-ELEMENTS - WS-I
                   
                   COMPUTE WS-J-PLUS-1 = WS-J + 1
                   
      * Comparaison alphabétique
                   IF PEOPLE-NAME  (WS-J) > PEOPLE-NAME  (WS-J-PLUS-1)
      * Échange des valeurs
                       MOVE PEOPLE-NAME  (WS-J) TO WS-TEMP-NOM
                       
                       MOVE PEOPLE-NAME  (WS-J-PLUS-1) 
                       TO PEOPLE-NAME (WS-J)
                       
                       MOVE WS-TEMP-NOM TO PEOPLE-NAME  (WS-J-PLUS-1)
                       
      * Indiquer qu'un échange a eu lieu
                       SET PAS-ENCORE-TRIE TO TRUE
                   END-IF
                   
               END-PERFORM
               
      * Si aucun échange n'a été fait, le tableau est déjà trié
               IF TABLEAU-TRIE
                   EXIT PERFORM
               END-IF
               
           END-PERFORM.
