      *  SNIPPET FOR UNDERSTANDING VSAM IN COBOL 
      *  READ EXISTING FILE AND KEY  
       
       IDENTIFICATION DIVISION.
       PROGRAM-ID. VSASNI3.
       AUTHOR. BUSSIERE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FICHIER-KV ASSIGN TO "base_kv.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE  IS DYNAMIC
               RECORD KEY   IS KV-CLE
      * Rajout du ile status pour le test d'ouverture
               FILE STATUS  IS WS-STATUS.



       DATA DIVISION.
      * FILE SECTION AVANT WORKING-STORAGE SECTION
       FILE SECTION.
       FD  FICHIER-KV.
       01  REGISTR-KV.
           05  KV-CLE       PIC X(10).
           05  KV-VALEUR    PIC X(50).

       WORKING-STORAGE SECTION.
      * WS pour Working Storage
       01  WS-TEXTE   PIC X(100) VALUE "Ceci 10 est le debut d un tres lon
      -    "g texte qui continue sur la ligne suivante".
       01  WS-INTEGER   PIC 9(2) VALUE 42.

       01 WS-STATUS PIC X(02).

       PROCEDURE DIVISION.
       0000-MAIN.
      * 1. On tente d'ouvrir en I-O pour préserver l'existant
           OPEN I-O FICHIER-KV
           
      * 2. Si le statut est "35" (Fichier physique introuvable)
           IF WS-STATUS = "35"
               *> On le crée proprement car il n'existe pas encore
               OPEN OUTPUT FICHIER-KV
               CLOSE FICHIER-KV
               *> Maintenant qu'il est créé vide, on le réouvre en I-O
               OPEN I-O FICHIER-KV
           END-IF.

           
           MOVE "MON_ID_01"  TO KV-CLE.
           MOVE "Hello World" TO KV-VALEUR.
           WRITE REGISTR-KV.
           
           CLOSE FICHIER-KV.

      *    2. LECTURE (GET) 
           OPEN I-O FICHIER-KV.
           
           MOVE "MON_ID_01"  TO KV-CLE.
           READ FICHIER-KV
               INVALID KEY 
                   DISPLAY "Clef non trouvee."
               NOT INVALID KEY 
                   DISPLAY "Valeur lue 1 : " KV-VALEUR
           END-READ.
      *    On laisse le fichier ouvert en I-O pour faire la suite !

      *    3. RÉÉCRITURE (UPDATE / REWRITE)
      *    Le fichier est déjà ouvert en I-O. On change la valeur et 
      *    on REWRITE.
           MOVE "MON_ID_01"  TO KV-CLE.
           MOVE "Hello World 2" TO KV-VALEUR.
           
           REWRITE REGISTR-KV
               INVALID KEY
                   DISPLAY "Erreur lors de la mise a jour."
           END-REWRITE.

      *    4. VÉRIFICATION : On relit immédiatement pour valider le changement
           MOVE "MON_ID_01"  TO KV-CLE.
           READ FICHIER-KV
               INVALID KEY 
                   DISPLAY "Clef non trouvee."
               NOT INVALID KEY 
                   DISPLAY "Valeur lue 2 : " KV-VALEUR
           END-READ.
           

           MOVE "MON_ID_02"  TO KV-CLE.
           READ FICHIER-KV
               INVALID KEY 
                   DISPLAY "Clef non trouvee."
               NOT INVALID KEY 
                   DISPLAY "Valeur lue 2 : " KV-VALEUR
           END-READ.

      *    On ferme proprement à la toute fin
           CLOSE FICHIER-KV.

           STOP RUN.
