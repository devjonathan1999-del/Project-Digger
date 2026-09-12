# Direction artistique intégrée — v0.8.1

La référence approuvée est désormais traduite en une scène Godot dynamique : surface industrielle illustrée, roche texturée, puits mécanique, ascenseur animé, chambres excavées, filons et foreuse. L’interface utilise une palette ardoise, acier et ambre, des pictogrammes de ressources et une navigation lisible.

Le jeu conserve ses règles, sa production, ses sauvegardes et ses événements. Les bâtiments restent des cibles interactives, placées dans le même repère que le dessin après déplacement de caméra et zoom. Les plaques affichent les débits réels. Le cristal représente une découverte ou un site réellement présent dans la partie ; son activation passe toujours par les actions existantes.

## Assets et intégration

Les PNG sont dans `assets/industry/final/`. La référence complète sert uniquement de guide ; elle n’est pas utilisée comme écran de jeu. Les éléments sont assemblés par `mine_portrait_painter.gd`, chargés par `mine_final_assets.gd`, et positionnés par `mine_asset_renderer.gd`. La présentation historique reste disponible en largeur desktop.

| Fichier | Brief de génération retenu |
| --- | --- |
| surface.png | Panorama industriel au crépuscule : chevalement central, ateliers latéraux, métal patiné, éclairage ambre, sol commun. |
| rock.png | Roche sombre détaillée, texture répétable, contraste discret pour préserver la lecture des installations. |
| chambers.png | Atlas de quatre chambres excavées : fer, charbon, cuivre et cristal ; machines en acier, passerelles et éclairage local. |
| shaft.png | Puits vertical mécanique, rails, câbles et structures métalliques, sans interface intégrée. |
| rigs.png | Ascenseur et foreuse séparés, vue frontale, acier et laiton, éclairage ambre. |
| seams.png | Filons de cuivre et de cristal cyan, illustrés séparément sur une roche sombre. |

Les images de sprites générées contenaient un fond neutre au lieu d’un canal alpha exploitable. Le chargeur retire uniquement le fond clair connecté au bord, une fois à la mise en cache, afin de conserver les détails métalliques intérieurs. Les sources sont conservées. Le chargement privilégie les ressources importées Godot et possède un repli pour le premier lancement avant import.

## Vérifications

- 18 scripts SceneTree exécutés avec code de sortie 0, dont `test_runner` et ses 20 suites de logique, sauvegarde, hors ligne et progression.
- `test_final_art_direction` vérifie les assets et leur transparence, les zones tactiles, la foreuse, les mines et les deux états du cristal. Il contrôle l’alignement à différents focus et zooms, ainsi que l’absence de mutation des stocks et de la progression par le rendu ou la sélection.
- Deux défauts détectés en revue ont été corrigés : largeur minimale décalant la cible de la foreuse et alignement du cristal avec son état réel. Les régressions correspondantes ont échoué avant correction puis réussi.
- Captures OpenGL inspectées à 720 × 1280 et 480 × 854, à 50 et 150 m et avec focus à 90 m. Clics natifs sur cuivre et foreuse confirmés dans le jeu avec production active.
- Import des nouveaux assets terminé avec code de sortie 0. Des avertissements de régénération de fichiers UID historiques subsistent ; aucune erreur de script n’a été constatée.

Captures et logs : `artifacts/portrait-v081/final/`. Le dossier est exclu de l’import Godot. La capture `v081-portrait-50m.png` montre le rendu réel ; `native-copper-click.jpg` et `native-drill-click.jpg` montrent les panneaux ouverts après clic.

Validation locale sous Godot 4.7.1 avec OpenGL. La CI déclarée sous 4.7.2 et un appareil mobile physique n’ont pas été exécutés dans cette passe. Le format 480 × 854 utilise le scaling canvas du projet.

## État livré

La composition, les matières et l’identité visuelle de la maquette sont intégrées. Le placement dépend désormais de la progression réelle : une partie à 50 m ne présente donc pas toutes les installations de la référence. Cette base permet de reprendre le gameplay ; une finition commerciale pourra encore enrichir les animations, les effets et la variété des décors.

Travail conservé sur `feature/portrait-polish-v0.8.1`, sans fusion dans `main` ni publication distante.
