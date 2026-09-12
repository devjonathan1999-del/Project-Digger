# Direction finale Project Digger
Référence approuvée : assets/industry/final/art-direction-reference.png.
Portrait 720×1280 : surface industrielle sur un sol commun, roche texturée sombre, chambres excavées reliées au puits, acier/brass/ambre, découvertes cyan discrètes. Interface compacte avec ressources identifiables et navigation ambre. Une vraie scène dynamique, pas une image de fond du jeu complet.
Préserver toutes les règles, production hors ligne, sauvegardes, événements et interactions. Trois mines restent accessibles même si leur profondeur illustrée dépasse le front. Hitboxes >=44 pixels logiques. Caméra, focus et zoom utilisent le même repère que le renderer. Conserver les assets historiques pour fallback et tests pertinents. Ne pas fusionner main.
Validation : capture réelle à50m et150m, focus90, petit écran480, clic cuivre production active ; tests runner, portrait et régressions visuelles pertinentes. Version locale Godot4.7.1, CI4.7.2 non présumée exécutée.
