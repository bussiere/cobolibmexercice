import unicodedata

def nettoyer_texte(texte):
    # 1. Normalisation : décompose les caractères accentués (ex: 'é' devient 'e' + '◌́')
    texte_normalise = unicodedata.normalize('NFD', texte)
    
    # 2. Filtrage : supprime les marques d'accents (catégorie 'Mn')
    texte_sans_accent = "".join(c for c in texte_normalise if unicodedata.category(c) != 'Mn')
    
    # 3. Conversion en majuscules
    return texte_sans_accent.upper()

# --- Exemple d'utilisation ---
if __name__ == "__main__":
    phrase_originale = """
      * Le niveau 77 identifie les entrées de description d'éléments 
      * de donnees qui sont des éléments indépendants 
    """
    phrase_nettoyee = nettoyer_texte(phrase_originale)
    print(phrase_nettoyee)
    with open("scripts/comment.txt", "w", encoding="utf-8") as fichier:
        fichier.write(phrase_nettoyee)
