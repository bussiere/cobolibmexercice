      * SNIPPET FOR UNDERSTANDING VAR IN COBOL

      *=========================================================*
      * TYPESCB - DEMO DES TYPES ET NIVEAUX DE VARIABLES COBOL  *
      * CIBLE : ANS COBOL IBM SOUS MVS 3.8 (HERCULES)           *
      * FORMAT FIXE : COL 1-6 SEQUENCE, COL 7 INDICATEUR,       *
      * COL 8-11 ZONE A, COL 12-72 ZONE B                       *
      * COMMENTAIRES SANS ACCENTS (EBCDIC)                      *
      *=========================================================*
      *

      * TODO A COMPLETER 
      * DIVISION D'IDENTIFICATION : NOM DU PROGRAMME
       IDENTIFICATION DIVISION.
      * NOM DU PROGRAMME, 8 CARACTERES MAXI SOUS MVS
       PROGRAM-ID. BASSNI1.
       AUTHOR. BUSSIERE.

      *
      * DIVISION D'ENVIRONNEMENT : MACHINE ET FICHIERS
       ENVIRONMENT DIVISION.
      * SECTION DE CONFIGURATION
       CONFIGURATION SECTION.
      * ORDINATEUR QUI COMPILE
       SOURCE-COMPUTER. IBM-370.
      * ORDINATEUR QUI EXECUTE
       OBJECT-COMPUTER. IBM-370.
      *
      * DIVISION DES DONNEES : TOUTES LES VARIABLES
       DATA DIVISION.
      * ZONE DE TRAVAIL EN MEMOIRE
       WORKING-STORAGE SECTION.
      *
      *---------------------------------------------------------*
      * NIVEAU 77 : VARIABLES ISOLEES, HORS DE TOUT GROUPE      *
      * (PLACEES AVANT LES 01 PAR PRUDENCE SUR VIEUX COMPILO)   *
      *---------------------------------------------------------*
      * COMPTEUR BINAIRE SIGNE, 4 CHIFFRES = 2 OCTETS
       77  W-COMPTEUR          PIC S9(4) COMP VALUE ZERO.
      * NOMBRE EN DISPLAY, 2 CHIFFRES = 2 OCTETS
       77  W-INDICE            PIC 99         VALUE 1.
      * USAGE INDEX : SAUVEGARDE D'UN INDEX, PAS DE PICTURE
       77  W-SAUVE-IX          USAGE INDEX.
      *
      *---------------------------------------------------------*
      * NIVEAU 01 : GROUPE DES TYPES DE PICTURE                 *
      *---------------------------------------------------------*
      * 01 = DEBUT D'UN GROUPE (PAS DE PIC SUR UN GROUPE)
       01  W-PICTURES.
      * X : ALPHANUMERIQUE, 10 CARACTERES QUELCONQUES
           05  W-X             PIC X(15)      VALUE 'TRAVELLER 1.5'.
      * A : ALPHABETIQUE, LETTRES ET ESPACES SEULEMENT
           05  W-A             PIC A(5)       VALUE 'ABCDE'.
      * 9 : NUMERIQUE NON SIGNE, 5 CHIFFRES
           05  W-9             PIC 9(5)       VALUE 12345.
      * S : NUMERIQUE SIGNE (SIGNE STOCKE DANS LE DERNIER OCTET)
           05  W-S9            PIC S9(3)      VALUE -42.
      * V : VIRGULE IMPLICITE, 3 ENTIERS + 2 DECIMALES, 5 OCTETS
           05  W-V             PIC 9(3)V99    VALUE 123.45.
      * P : FACTEUR D'ECHELLE, 999PP VAUT 3 CHIFFRES X 100
           05  W-P             PIC 999PP.
      *
      *---------------------------------------------------------*
      * NIVEAU 01 : GROUPE DES TYPES DE STOCKAGE (USAGE)        *
      *---------------------------------------------------------*
       01  W-USAGES.
      * DISPLAY (DEFAUT) : 1 OCTET EBCDIC PAR CHIFFRE
           05  W-DISP          PIC S9(5)  USAGE DISPLAY VALUE 100.
      * COMP : BINAIRE, 1 A 4 CHIFFRES = DEMI-MOT (2 OCTETS)
           05  W-COMP-H        PIC S9(4)  COMP   VALUE 200.
      * COMP : BINAIRE, 5 A 9 CHIFFRES = MOT (4 OCTETS)
           05  W-COMP-F        PIC S9(9)  COMP   VALUE 300.

      *
      *---------------------------------------------------------*
      * NIVEAUX 01 / 05 / 10 / 88 / 66 : UN PERSONNAGE          *
      *---------------------------------------------------------*
      * 01 : L'ENREGISTREMENT COMPLET
       01  W-PERSO.
      * 05 : SOUS-ZONE ELEMENTAIRE (A UNE PIC)
           05  W-NOM           PIC X(20)      VALUE 'JAMISON'.
      * 05 : SOUS-GROUPE (PAS DE PIC, IL CONTIENT DES 10)
           05  W-UPP.
      * 10 : NIVEAU INFERIEUR, FORCE
               10  W-FOR       PIC 9          VALUE 7.
      * 10 : DEXTERITE
               10  W-DEX       PIC 9          VALUE 8.
      * 10 : ENDURANCE
               10  W-END       PIC 9          VALUE 6.
      * 05 : STATUT SUR UN CARACTERE
           05  W-STATUT        PIC X          VALUE 'V'.
      * 88 : CONDITION VRAIE SI W-STATUT = 'V'
               88  VIVANT                     VALUE 'V'.
      * 88 : CONDITION VRAIE SI W-STATUT = 'M'
               88  MORT                       VALUE 'M'.
      * 88 : PLUSIEURS VALEURS POSSIBLES
               88  STATUT-OK                  VALUE 'V' 'M'.
      * 05 : AGE EN ANNEES
           05  W-AGE           PIC 99         VALUE 18.
      * 88 : PLAGE DE VALEURS AVEC THRU
               88  JEUNE                      VALUE 18 THRU 33.
      * 66 : RENAMES, REGROUPE FOR ET DEX SOUS UN AUTRE NOM
      * (DOIT SUIVRE LA DERNIERE ZONE DE L'ENREGISTREMENT)
       66  W-FORDEX            RENAMES W-FOR THRU W-DEX.
      *
      *---------------------------------------------------------*
      * TABLE : OCCURS AVEC INDEX                               *
      *---------------------------------------------------------*
       01  W-TABLE.
      * 6 CARACTERISTIQUES D'UN CHIFFRE, INDEX IX-CAR
           05  W-CARAC         PIC 9  OCCURS 6 TIMES
                                      INDEXED BY IX-CAR.
      *
      *---------------------------------------------------------*
      * ZONES EDITEES : UNIQUEMENT POUR L'AFFICHAGE             *
      * (PAS DE CALCUL POSSIBLE DESSUS)                         *
      *---------------------------------------------------------*
       01  W-EDITION.
      * Z : REMPLACE LES ZEROS DE TETE PAR DES ESPACES
           05  E-ZERO          PIC ZZZZ9.
      * - FLOTTANT : SIGNE MOINS SI NEGATIF, ESPACE SINON
           05  E-SIGNE         PIC -ZZZ9.
      * VIRGULES DE MILLIERS, POINT DECIMAL, SIGNE EN FIN
           05  E-MONTANT       PIC Z,ZZZ,ZZ9.99-.
      * * : REMPLACE LES ZEROS DE TETE PAR DES ETOILES (CHEQUES)
           05  E-ETOILE        PIC ***,**9.99.
      * CR : AFFICHE CR SI NEGATIF (DB EXISTE AUSSI)
           05  E-CREDIT        PIC ZZ,ZZ9.99CR.
      * $ FLOTTANT : SYMBOLE MONETAIRE COLLE AU CHIFFRE
           05  E-DOLLAR        PIC $$$,$$9.99.
      * / : INSERE DES BARRES, POUR UNE DATE
           05  E-DATE          PIC 99/99/99.
      * B : INSERE UN ESPACE
           05  E-BLANC         PIC XXBXX.
      * 0 : INSERE UN ZERO
           05  E-ZEROINS       PIC 9900.
      *
      * DIVISION DE TRAITEMENT : LES INSTRUCTIONS
       PROCEDURE DIVISION.
      * PARAGRAPHE PRINCIPAL
       DEBUT.
      * AFFICHE UN ALPHANUMERIQUE TEL QUEL
           DISPLAY 'X      : ' W-X.
      * AFFICHE UN ALPHABETIQUE
           DISPLAY 'A      : ' W-A.
      * ZERO SUPPRIME : 12345 RESTE 12345
           MOVE W-9 TO E-ZERO.
           DISPLAY '9      : ' E-ZERO.
      * SIGNE : -42 S'AFFICHE '  -42'
           MOVE W-S9 TO E-SIGNE.
           DISPLAY 'S9     : ' E-SIGNE.
      * VIRGULE IMPLICITE RENDUE VISIBLE PAR L'EDITION
           MOVE W-V TO E-MONTANT.
           DISPLAY 'V      : ' E-MONTANT.
      * P : ON RANGE 12300, SEULS 123 SONT STOCKES
           MOVE 12300 TO W-P.
           MOVE W-P TO E-ZERO.
           DISPLAY 'P      : ' E-ZERO.
      *
      * BINAIRE DEMI-MOT VERS EDITION
           MOVE W-COMP-H TO E-ZERO.
           DISPLAY 'COMP H : ' E-ZERO.
      * BINAIRE MOT VERS EDITION
           MOVE W-COMP-F TO E-ZERO.
           DISPLAY 'COMP F : ' E-ZERO.
      * DOLLAR FLOTTANT SUR LA VALEUR ABSOLUE
           MOVE 1500.75 TO E-DOLLAR.
           DISPLAY 'DOLLAR : ' E-DOLLAR.
      * DATE JJMMAA AVEC BARRES
           MOVE 161126 TO E-DATE.
           DISPLAY 'DATE   : ' E-DATE.
      * 'ABCD' DEVIENT 'AB CD'
           MOVE 'ABCD' TO E-BLANC.
           DISPLAY 'BLANC  : ' E-BLANC.
      * 42 DEVIENT 4200
           MOVE 42 TO E-ZEROINS.
           DISPLAY 'ZERO   : ' E-ZEROINS.
      *
      * GROUPE ENTIER : AFFICHE TOUTES SES ZONES COLLEES
           DISPLAY 'PERSO  : ' W-PERSO.
      * SOUS-GROUPE UPP : '786'
           DISPLAY 'UPP    : ' W-UPP.
      * RENAMES : SEULEMENT FOR ET DEX, '78'
           DISPLAY 'FORDEX : ' W-FORDEX.
      * TEST D'UN 88 : W-STATUT VAUT 'V'
           IF VIVANT
               DISPLAY 'STATUT : VIVANT'.
      * ON CHANGE LA VALEUR SOUS-JACENTE (PAS DE SET TO TRUE)
           MOVE 'M' TO W-STATUT.
      * LE 88 MORT EST MAINTENANT VRAI
           IF MORT
               DISPLAY 'STATUT : MORT'.
      * 88 SUR UNE PLAGE : 18 EST ENTRE 18 ET 33
           IF JEUNE
               DISPLAY 'AGE    : JEUNE'.
      *
      * BOUCLE SUR LA TABLE AVEC L'INDEX
           PERFORM REMPLIR
               VARYING IX-CAR FROM 1 BY 1
               UNTIL IX-CAR > 6.
      * SAUVEGARDE DE L'INDEX DANS LA ZONE USAGE INDEX
           SET W-SAUVE-IX TO IX-CAR.
      * AFFICHE LES 6 CHIFFRES DE LA TABLE
           DISPLAY 'TABLE  : ' W-TABLE.
      * INCREMENTE LE COMPTEUR BINAIRE 77
           ADD 1 TO W-COMPTEUR.
           MOVE W-COMPTEUR TO E-ZERO.
           DISPLAY 'COMPT  : ' E-ZERO.
      * FIN DU PROGRAMME
           STOP RUN.
      *
      * REMPLIT UNE CASE : W-CARAC(I) = I
       REMPLIR.
      * SET CONVERTIT L'INDEX EN NUMERO DE CASE
           SET W-INDICE TO IX-CAR.
      * RANGE LE NUMERO DANS LA CASE COURANTE
           MOVE W-INDICE TO W-CARAC (IX-CAR).
