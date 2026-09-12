# Économie industrielle v0.9

## Comportement livré

Les 100 recettes proposées sont intégrées, avec leurs ingrédients, durées et rendements. Le catalogue contient 114 ressources. Six installations disposent chacune d’un lot indépendant : Fonderie, Atelier, Usinage, Chimie, Électronique et Laboratoire cristallin. Elles peuvent produire en parallèle, pendant que la foreuse et l’exploration travaillent.

Les recettes sont identifiées par palier dans l’écran Industrie. La recherche porte sur leur nom et leurs ingrédients ; un filtre limite la liste aux recettes débloquées à la profondeur actuelle. Les fiches affichent les stocks détenus/requis, les lots, le rendement total et le temps. Le choix explicite de recette et la quantité sont conservés pendant les mises à jour et après filtrage. L’inventaire complet et les extractions se trouvent après les installations ; le HUD principal reste compact.

Les neuf nouvelles matières premières minérales se débloquent automatiquement dans leur zone et disposent d’une extraction améliorable. Le cristal reste produit par les cavités explorées. Les fragments anciens sont récupérés depuis les structures réellement ouvertes et actives, à partir de 1 000 m : une opération de cinq minutes donne un fragment et peut être relancée. Une structure ancienne est garantie à cette profondeur ; une découverte historique occupant déjà son emplacement n’est pas écrasée.

La descente reste découpée en pas de 10 m, mais les transitions majeures exigent les équipements fabriqués dans la zone précédente. Les pièces sont payées au lancement et installées à la fin du chantier. Les équipements installés sont réutilisés pour les transitions et améliorations correspondantes, sans nouveau paiement. Le Centre demande lui aussi des composants industriels et s’étend jusqu’aux zones profondes. La progression nouvelle s’arrête à 1 500 m, avec le cœur abyssal comme objectif final de fabrication.

## Sauvegardes et hors ligne

Le format 3 conserve les stocks, niveaux, profondeur, sites et travaux en cours. Les formats 1 et 2 sont d’abord validés par des versions figées des anciens validateurs, puis migrés vers le nouveau catalogue. Les équipements correspondant à la progression historique sont reconnus, sans obligation de rejouer les anciens paliers. Les stocks ajoutés commencent à zéro.

Un lot déjà payé conserve son rendement et sa durée engagés. Les travaux progressent hors ligne et sont crédités une seule fois. Les anciennes parties dépassant déjà 1 500 m et leurs forages engagés restent chargeables ; la nouvelle limite n’efface pas leur profondeur. Les sauvegardes invalides restent protégées contre l’écrasement.

## Vérification

- 22 scripts SceneTree exécutés avec code de sortie 0 et sans `SCRIPT ERROR`/`ERROR`. Le runner existant contient 20 suites de logique, sauvegarde, progression et terrain.
- Nouveaux tests de catalogue, simulation, interface et parcours. Le catalogue a été comparé aux 100 lignes source : installations, quantités, temps et rendements concordent avec les abréviations normalisées dans la conception approuvée.
- Tests des rendements multiples, six productions parallèles, déblocages de profondeur, paiements atomiques, réutilisation des têtes, migrations valides et invalides, sauvegardes avec travaux actifs, récupération hors ligne et préservation de découvertes historiques.
- Parcours depuis les stocks initiaux, sans injection de pièces ni de profondeur : fabrication des équipements, exploration des sites, récupération des fragments, arrivée à 1 500 m, fabrication de la recette 100 et rechargement final. 6 175 travaux de fabrication dans ce parcours volontairement séquentiel.
- Régressions de clic réel : appui maintenu sur le bouton de récupération, mise à jour de la session, bouton encore valide, relâchement déclenchant le travail. Le rendu des structures anciennes indique la récupération plutôt qu’un faux débit nul.
- Captures OpenGL de l’écran Industrie, de la surface et du focus à 1 000 m inspectées. Largeurs logiques 480 et 720 contrôlées sans débordement horizontal. La direction artistique précédente est conservée.
- Revue indépendante de l’ensemble puis des corrections : aucun problème important restant signalé. `git diff --check` passe.

Logs et captures locaux : `artifacts/economy-v09/`. Les captures de l’interface utilisent une partie de test pour exposer les six installations ; elles ne modifient pas la sauvegarde du joueur. Le parcours de fabrication utilise une autre sauvegarde isolée.

## Mesure initiale, pas un équilibrage final

Le parcours de test fabrique les ingrédients en série, sans améliorer les mines ou accélérer la foreuse et sans optimiser les productions parallèles. Il valide l’accessibilité des chaînes, pas la durée attendue d’une partie.

| Objectif | Temps simulé de cette stratégie séquentielle |
| --- | --- |
| 30 m | 7 min 45 s |
| 90 m | 3 h 49 min 15 s |
| 500 m | environ 2 jours 2 h |
| 1 000 m | environ 10 jours 6 h |
| 1 500 m | environ 21 jours 11 h |
| Cœur abyssal fabriqué | environ 31 jours 22 h |

Ces chiffres montrent que l’équilibrage devra prendre en compte les dépendances et le parallélisme, pas seulement la durée affichée de chaque recette. Les temps et quantités source ont été conservés comme demandé. Les améliorations de vitesse et d’emplacements des usines restent à concevoir avec cette cadence ; la première intégration fournit un emplacement par bâtiment.

Vérification locale : Godot 4.7.1, OpenGL compatibility. CI 4.7.2 configurée mais non exécutée ici ; aucun appareil mobile physique testé. Aucun nouveau décor illustré spécifique aux neuf matières n’a été ajouté : leur gestion est opérationnelle dans Industrie, avec les visuels historiques conservés pour la mine.

Branche : `feature/industrial-economy-v0.9`. Aucun push ni fusion dans `main`.
