      *  SNIPPET FOR UNDERSTANDING VSAM IN COBOL
       IDENTIFICATION DIVISION.
       PROGRAM-ID. VSASNI1.
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
      *    1. ÉCRITURE (PUT) : On cree le fichier et on insère 
      *    la paire clé/valeur
      *    Ecrase l'existant
           OPEN OUTPUT FICHIER-KV.
           
           MOVE "MON_ID_01"  TO KV-CLE.
           MOVE "Bonjour la Terre !" TO KV-VALEUR.
           WRITE REGISTR-KV.
           
           CLOSE FICHIER-KV.

      *    2. LECTURE (GET) : On réouvre pour lire directement via la clé
           OPEN I-O FICHIER-KV.
           
           MOVE "MON_ID_01"  TO KV-CLE.
           READ FICHIER-KV
               INVALID KEY 
                   DISPLAY "Clé non trouvée."
               NOT INVALID KEY 
                   DISPLAY "Valeur lue : " KV-VALEUR
           END-READ.
           
           CLOSE FICHIER-KV.
           STOP RUN.
