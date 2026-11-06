      *  SNIPPET FOR UNDERSTANDING VSAM IN COBOL 
      *  REWRITE KEY  
       IDENTIFICATION DIVISION.
       PROGRAM-ID. VSASNI2.
       AUTHOR. BUSSIERE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FICHIER-KV ASSIGN TO "base_kv.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE  IS DYNAMIC
               RECORD KEY   IS KV-CLE.

       DATA DIVISION.
       FILE SECTION.
       FD  FICHIER-KV.
       01  REGISTR-KV.
           05  KV-CLE       PIC X(10).
           05  KV-VALEUR    PIC X(50).

       PROCEDURE DIVISION.
       0000-MAIN.
      *    1. ÉCRITURE INITIALE (PUT) : On crée le fichier
           OPEN OUTPUT FICHIER-KV.
           
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

           MOVE "MON_ID_02"  TO KV-CLE.
           MOVE "Hello World 3" TO KV-VALEUR.
      * Comment savoir si une clef a deja ete ecrite ?
           WRITE REGISTR-KV
               INVALID KEY
                   DISPLAY "Erreur lors de la mise a jour."
           END-WRITE.


      *    4. VÉRIFICATION : On relit immédiatement pour valider le changement
           MOVE "MON_ID_01"  TO KV-CLE.
           READ FICHIER-KV
               INVALID KEY 
                   DISPLAY "Clef non trouvee."
               NOT INVALID KEY 
                   DISPLAY "Valeur lue 2 : " KV-VALEUR
           END-READ.
           
      *    On ferme proprement à la toute fin
           CLOSE FICHIER-KV.

           STOP RUN.
