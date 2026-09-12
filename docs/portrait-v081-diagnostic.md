# Diagnostic portrait local — 12 septembre 2026

## Montage et observation

- Dépôt local : `C:/Users/debui/Documents/GitHub/Project-Digger`.
- Fetch GitHub effectué ; `main` et `origin/main` : `980b5fc98ebb5c0f8c9b13e0da6451a2214b129f`.
- Branche de travail : `feature/portrait-polish-v0.8.1`.
- Godot local : **4.7.1 stable**, OpenGL Compatibility, AMD Radeon RX 7600. La version CI annoncée est 4.7.2 ; elle n'a pas été exécutée localement.
- Scène de démarrage : `scenes/main.tscn`, instance de `scenes/industry.tscn`. Interface construite par `industry_screen.gd`.
- Projet exécuté depuis l'éditeur (F5), puis dans une fenêtre autonome **720 × 1280**. Captures natives du jeu réel à 50 m ; contrôle complémentaire OpenGL local avec état de test à 150 m, caméra surface puis 90 m.
- Le lancement du moteur dans le sandbox plante avant le test ; les lancements hors sandbox fonctionnent. Le dialogue résiduel du processus planté a été fermé.

## Défauts constatés et première passe

| Élément | Constat réel | Action |
| --- | --- | --- |
| HUD | Deux lignes contenues, ressources et profondeur visibles. Noms des ressources très petits. | Structure conservée ; taille des noms à revoir ensuite sur écran mobile physique. |
| Navigation | Quatre onglets contenus en bas, hauteur confortable. | Conservée. |
| Puits | Station de 270 × 154 px centrée sur les rails, masquant l'axe principal. | Stations ramenées à 180 × 102 px et placées alternativement à droite/gauche avec raccord au puits. Assets conservés. |
| Installations | Fer gauche à 22 m, charbon droite à 50 m, cuivre gauche à 78 m : alternance existante correcte. | Composition conservée pour cette première passe. |
| Zones tactiles | Boutons restés à 12 m alors que les illustrations sont réparties en profondeur. | Boutons alignés sur les rectangles des assets ; dimensions 205 × 112 px ; visibilité synchronisée. Vérification après déplacement de caméra. |
| Labels | 10 px et opacité de repos 0,24, quasiment invisibles sur le fond sombre. | Portrait : 14 px, opacité de repos 0,90, hauteur 26 px. Apparence desktop conservée. |
| Clics réels | Avec la production active, boutons détruits entre l'appui et le relâchement par les rafraîchissements continus. | Conservation des cibles pendant un appui. Test reproduisant le défaut avant correction ; clic cuivre autonome confirmé après correction. |
| Surface | Barre des raccourcis superposée aux bâtiments et au chevalement, sans véritable espace réservé. | Reste à corriger. |
| Profondeur | Repères dessinés par le fond historique recouverts par le renderer opaque ; lecture métrique trop faible. | Reste à corriger dans le renderer visible. |
| Front de forage | À 50 m, cuivre illustré à 78 m sous la fin du puits ; grand espace rocheux en dessous. La foreuse est surtout indiquée par un label. | Reste à clarifier visuellement, en préservant l'accès aux trois mines existantes. |
| Découvertes | À 150 m, plusieurs galeries et halos concurrencent les installations ; le cristal illustré n'a pas de label d'identité propre. | Reste à hiérarchiser. |

## Corrections suivantes réalisées

1. Bande dédiée aux raccourcis, boutons de 44 px en portrait, surface illustrée dessous. Bâtiments répartis en deux voies latérales sans recouvrir le puits ; grue conservée quand débloquée. Alertes déplacées en bas de la mine et leur espace vide ne bloque plus les clics. Noms du HUD agrandis à 12 px.
2. Repères métriques dessinés dans le renderer visible et placés à côté du puits, du côté opposé aux stations. Origine verticale calculée à partir de la largeur actuelle du monde, y compris au passage du seuil de 800 px.
3. Front creusé marqué par une foreuse, une bande de sécurité et le prochain palier. Roche future atténuée ; mentions « réseau initial » sur les mines disponibles sous le front. Leurs interactions et débits restent inchangés.
4. Galeries secondaires, reliefs mécaniques et halos simplifiés en portrait ; strates prolongées jusqu'au bas de la vue. Cristal identifié par un label lisible sans nouvelle interaction.
5. Captures OpenGL à 720 × 1280 et 480 × 854 vérifiées. Le second format utilise le scaling canvas du projet ; la géométrie des bâtiments est aussi contrôlée directement à 480 px logiques. Aucun écran mobile physique testé.

Les lignes « Reste à corriger » du tableau décrivent le diagnostic avant cette seconde passe ; les actions ci-dessus les résolvent.

## Validation finale des corrections

- Codes de sortie 0 : `test_runner` (20 suites, dont sauvegardes, hors ligne, progression et événements), `test_portrait_v08`, `test_industry_ui`, `test_progression_ui_actions`, `test_progression_ui_events`, les tests UI/world v0.4, markers/world v0.5, responsive/modules/geology v0.6 et interactions/renderer/resources/assets v0.7 : 16 exécutions SceneTree réussies.
- Le script RefCounted `test_visual_v05_layout` est exécuté par `test_runner` ; son lancement direct accidentel a été arrêté et n'est pas compté comme test réussi.
- Après revue : test portrait et runner relancés avec succès. Sauvegarde de test isolée avant l'ajout de la scène ; régression sur l'origine verticale à 720/1000/720 px.
- Parcours portrait avec rendu OpenGL local : code de sortie 0, captures surface à 50/150 m, largeur 480 px et caméra à 90 m inspectées.
- Clic natif sur le cuivre confirmé avec production active après les corrections visuelles. Revue indépendante : les deux défauts signalés ont été corrigés, aucun autre problème important relevé.
- Captures finales : `artifacts/portrait-v081/polish/`. Modifications sur `feature/portrait-polish-v0.8.1`, sans fusion dans main.

## Validation de cette passe

- Régression ajoutée au test v0.8 : zones tactiles alignées après focus 0/90 m ; maintien d'un bouton pendant un appui puis sélection effective ; lisibilité au repos. Échecs observés avant corrections, succès après.
- Test v0.8 utilise une sauvegarde de test dédiée pour ses mutations à 150 m, au lieu de persister cet état artificiel dans la sauvegarde normale à la sortie.
- Codes de sortie 0 : `test_runner`, `test_portrait_v08`, `test_visual_v07_interactions`, `test_visual_v07_renderer`, `test_visual_v07_resources`, `test_visual_v06_responsive`, `test_visual_v05_markers`, `test_visual_v04_ui`.
- Test portrait exécuté aussi avec **rendu OpenGL local**, captures produites, code de sortie 0.
- L'assertion v0.6 de repos a été actualisée : absence d'emphase toujours exigée, lisibilité au repos désormais exigée en portrait. Les tests desktop de marqueurs passent.
- Capture native de l'ouverture réelle de « Mine de cuivre » après clic sur le bâtiment, production active.
- Aucun changement de règles de gameplay, de schéma de sauvegarde ou d'assets raster. Les fichiers de cache Godot déjà présents restent hors du changement de code.

Captures et logs locaux : `artifacts/portrait-v081/` (dossier exclu de l'import Godot par `artifacts/.gdignore`). `before.jpg` et `after.jpg` sont des captures natives du jeu réel ; les PNG `v08-portrait-*` sont les vues du parcours de test rendu local.

## Intégration de la direction finale

La passe suivante ajoute les assets raster et leur assemblage dynamique. Le bilan à jour est dans [final-art-direction.md](final-art-direction.md) ; les captures finales sont dans artifacts/portrait-v081/final/.
