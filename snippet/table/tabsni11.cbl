      * SNIPPET FOR UNDERSTANDING TABLE IN COBOL
      * BINARY SEARCH IN COBOL
      * COMPRENDRE LE TRI DE TABLEAU
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TABLE-TEST8.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * LE NIVEAU 77 IDENTIFIE LES ENTREES DE DESCRIPTION D'ELEMENTS 
      * DE DONNEES QUI SONT DES ELEMENTS INDEPENDANTS 
       77 PEOPLE-SEARCH-DATA     PIC X(20).
       01 PEOPLE-SERIAL.
           05 PEOPLE-NAME PIC X(20) OCCURS 50 TIMES
           ASCENDING KEY IS PEOPLE-NAME
           INDEXED BY PL-IDX .
           05 PL-FLAG        PIC X(01).
              88 SEARCH-DONE     VALUE 'O'.
              88 SEARCH-NDONE    VALUE 'N'.
      
      
      * Variables ajoutées pour scanner les doublons
      * LA BONNE PRATIQUE POUR NE PAS ENCOMBRER LE CODE DE SEARCH 
      * BINAIRE EST DE SAUVEGARDER L INDEX ET DE FAIRE DANS UNE AUTRE
      * PROCEDURE
           05 WS-START-IDX       PIC 9(02).
           05 WS-SCAN-IDX        PIC 9(02).
           05 WS-FOUND-ANY       PIC X(01) VALUE 'N'.
              88 FOUND-MATCH     VALUE 'O'.
              88 NO-MATCH        VALUE 'N'.

      * Variables de travail pour le tri
       01  WS-VARIABLES-TRI.
           05 WS-TEMP-NOM         PIC X(30).
           05 WS-MAX-ELEMENTS     PIC 9(02) VALUE 50.
           05 WS-I                PIC 9(02).
           05 WS-J                PIC 9(02).
           05 WS-J-PLUS-1         PIC 9(02).
           05 WS-SWAP-FLAG        PIC X(01).
      * METTRE UN RAPPEL DE 88
              88 TABLEAU-TRIE     VALUE 'O'.
              88 PAS-ENCORE-TRIE  VALUE 'N'.

         
       PROCEDURE DIVISION.
      * MOVE EST INUTILE NOUS ALLON TRIER LES DONNEES
      *    MOVE HIGH-VALUES TO PEOPLE-SERIAL.
      
      
      * MOVE POUR LES DONNEES
           MOVE "TITI" TO PEOPLE-NAME(1).
           MOVE "TOTO" TO PEOPLE-NAME(2).
           MOVE "TOTO" TO PEOPLE-NAME(3).
           MOVE "TATA" TO PEOPLE-NAME(4).
           MOVE "TITI" TO PEOPLE-NAME(5).
           MOVE "TOTO" TO PEOPLE-NAME(6).
           MOVE "TOTO" TO PEOPLE-SEARCH-DATA.
      * ON APPEL ICI L OPERATION DE TRIAGE DE TABLEAU
           PERFORM TRIER-TABLEAU.

           SEARCH ALL PEOPLE-NAME
           AT END DISPLAY "Not found"
           WHEN PEOPLE-SEARCH-DATA = PEOPLE-NAME(PL-IDX)
      * La variable FOUND MATCH A true 
           SET FOUND-MATCH TO TRUE
      * On sauvegarde l'index trouve pour travailler apres
           SET WS-START-IDX TO PL-IDX
           DISPLAY "Found"
           DISPLAY "INDEX :"
           DISPLAY PL-IDX
           DISPLAY "NOM :"
           DISPLAY PEOPLE-SEARCH-DATA
           DISPLAY  PEOPLE-NAME(PL-IDX).

      * Si on a trouvé au moins un élément, on balaie la zone
           IF FOUND-MATCH
               PERFORM BALAYER-DOUBLONS
           END-IF.

           STOP RUN.

       BALAYER-DOUBLONS.

           DISPLAY "--- DEBUT DE L'AFFICHAGE DES RESULTATS ---"
           
      * 1. REMONTER VERS LE DEBUT : On cherche la première occurrence réelle
           SET PL-IDX TO WS-START-IDX
           PERFORM UNTIL PL-IDX < 1 
              OR PEOPLE-NAME(PL-IDX) NOT = PEOPLE-SEARCH-DATA
                 SET WS-SCAN-IDX TO PL-IDX
                 SET PL-IDX DOWN BY 1
           END-PERFORM
           
      * À ce stade, WS-SCAN-IDX pointe sur le TOUT PREMIER doublon
           DISPLAY "Premiere occurrence trouvee a l'index : " 
                   WS-SCAN-IDX
           
      * 2. DESCENDRE VERS LA FIN : On affiche tout depuis ce premier point
           SET PL-IDX TO WS-SCAN-IDX
           PERFORM UNTIL PL-IDX > WS-MAX-ELEMENTS 
              OR PEOPLE-NAME(PL-IDX) NOT = PEOPLE-SEARCH-DATA
              
                 DISPLAY "Index : " PL-IDX " | Nom : " 
                 PEOPLE-NAME(PL-IDX)
                 
                 SET PL-IDX UP BY 1
           END-PERFORM
           DISPLAY "--- FIN DES RESULTATS ---".


        TRIER-TABLEAU.
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > WS-MAX-ELEMENTS - 1
      * QU EST CE QUE L ON PEUT PASSER EN BOOLEAN          
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
