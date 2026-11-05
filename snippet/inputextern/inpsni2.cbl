       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRAVELLER-SHEET.
       AUTHOR. BUSSIERE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CHAR-FILE ASSIGN TO "char_input1.txt"
           ORGANIZATION IS LINE SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       FD  CHAR-FILE.
       01  CHAR-RECORD         PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-FS               PIC XX.
       01  WS-EOF              PIC X           VALUE "N".
           88  EOF-REACHED                     VALUE "Y".

       01  WS-COUNTER          PIC 9(2)        VALUE 1.

      * --- VARIABLES POUR LES DÉCOUPAGES ---
       01  WS-POINTER          PIC 9(3)        VALUE 1.
       01  WS-SKILL-COUNT      PIC 9(2)        VALUE 0.
       
      * Chaîne temporaire pour stocker la compétence brute avant son sous-split
       01  WS-TMP-SKILL        PIC X(20).
       01  WS-SUB-POINTER      PIC 9(3).

      * --- NOUVELLE STRUCTURE DU TABLEAU DE COMPÉTENCES ---
       01  WS-SKILLS-TABLE.
      * WS-SKILL-ROW est une ligne de 16 slots (15 char + 1 num)
           05 WS-SKILL-ROW OCCURS 5 TIMES.
               10 WS-SKILL-NAME    PIC X(15).
               10 WS-SKILL-LEVEL   PIC 9.

       01  WS-IDX              PIC 9(2).

      * Structure de la fiche stockee en memoire
       01  CHARACTER-SHEET.
           05 CHAR-NAME        PIC X(30).
           05 CHAR-CLASS       PIC X(20).
           05 CHAR-TERMS       PIC X(02).
           05 CHAR-UWP         PIC X(06).
           05 CHAR-CREDITS     PIC X(10).
           05 CHAR-SKILLS      PIC X(50).

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           OPEN INPUT CHAR-FILE
           IF WS-FS NOT = "00"
               DISPLAY "ERREUR OUVERTURE FICHIER. STATUS: " WS-FS
               STOP RUN
           END-IF

           PERFORM UNTIL EOF-REACHED
               READ CHAR-FILE
                   AT END
                       SET EOF-REACHED TO TRUE
                   NOT AT END
                       PERFORM PROCESS-LINE
               END-READ
           END-PERFORM

           CLOSE CHAR-FILE
           PERFORM DISPLAY-SHEET
           STOP RUN.

       PROCESS-LINE.
           EVALUATE WS-COUNTER
               WHEN 1 MOVE CHAR-RECORD TO CHAR-NAME
               WHEN 2 MOVE CHAR-RECORD TO CHAR-CLASS
               WHEN 3 MOVE CHAR-RECORD TO CHAR-TERMS
               WHEN 4 MOVE CHAR-RECORD TO CHAR-UWP
               WHEN 5 MOVE CHAR-RECORD TO CHAR-CREDITS
               WHEN 6 
                   MOVE CHAR-RECORD TO CHAR-SKILLS
                   PERFORM SPLIT-SKILLS
           END-EVALUATE
           ADD 1 TO WS-COUNTER.

       SPLIT-SKILLS.
           MOVE 1 TO WS-POINTER
           MOVE 0 TO WS-SKILL-COUNT
           
      * 1. On sépare d'abord les blocs par les virgules dans des 
      * variables temporaires
      * CASSE GUEULE COMME SYSTEME
           UNSTRING CHAR-SKILLS DELIMITED BY ","
               INTO WS-SKILL-ROW(1)
                    WS-SKILL-ROW(2)
                    WS-SKILL-ROW(3)
                    WS-SKILL-ROW(4)
                    WS-SKILL-ROW(5)
      * Le pointeur sert a dire ou l'on est sur la ligne de data
               WITH POINTER WS-POINTER
               TALLYING IN WS-SKILL-COUNT
           END-UNSTRING.
           DISPLAY "SKILLS DEBUG"
           DISPLAY  WS-SKILL-ROW(1).

      * 2. On boucle sur le nombre d'éléments trouvés pour 
      * séparer le Nom et le Niveau
           PERFORM VARYING WS-IDX FROM 1 BY 1 
                   UNTIL WS-IDX > WS-SKILL-COUNT
               
      *        Sauvegarde et nettoyage des espaces initiaux 
      * (ex: " Gunnery-1" -> "Gunnery-1")
               MOVE WS-SKILL-ROW(WS-IDX) TO WS-TMP-SKILL
               INSPECT WS-TMP-SKILL TALLYING WS-SUB-POINTER 
                       FOR LEADING SPACES
               
      * Réinitialisation de la ligne du tableau avant 
      * extraction propre
      * INITIALIZE REMPLACE PAR LES VALEURS PAR DEFAUT SELON LE TYPE
      * DES ESPACES POUR DU TEXT ET 0 POUR DES VALEURS
               INITIALIZE WS-SKILL-ROW(WS-IDX)
               MOVE 1 TO WS-SUB-POINTER
               
      *        Découpage par le tiret "-"
               UNSTRING WS-TMP-SKILL DELIMITED BY "-"
                   INTO WS-SKILL-NAME(WS-IDX)
                        WS-SKILL-LEVEL(WS-IDX)
                   WITH POINTER WS-SUB-POINTER
               END-UNSTRING
           END-PERFORM.

       DISPLAY-SHEET.
           DISPLAY "========================================"
           DISPLAY "       FICHE DE PERSONNAGE TRAVELLER    "
           DISPLAY "========================================"
           DISPLAY "Nom         : " CHAR-NAME
           DISPLAY "Carriere    : " CHAR-CLASS
           DISPLAY "Mandats (n) : " CHAR-TERMS
           DISPLAY "UWP         : " CHAR-UWP
           DISPLAY "Credits     : " CHAR-CREDITS " Cr"
           DISPLAY "----------------------------------------"
           DISPLAY "Liste des Competences decoulées :"
           
           PERFORM VARYING WS-IDX FROM 1 BY 1 
                   UNTIL WS-IDX > WS-SKILL-COUNT
               DISPLAY "  - Nom : " WS-SKILL-NAME(WS-IDX)
                       " | Niveau : " WS-SKILL-LEVEL(WS-IDX)
           END-PERFORM
           
           DISPLAY "NB COMPETENCE(S) : "  WS-SKILL-COUNT
           DISPLAY "========================================".
