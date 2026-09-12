# Économie industrielle — proposition d’intégration

Statut : conception approuvée par le joueur ; intégration réalisée, bilan dans docs/economy-v09.md.

## Base retenue

La liste fournie par le joueur constitue le catalogue de référence : 100 recettes, réparties en dix zones jusqu’à 1 500 m. Ses quantités, rendements et durées sont conservés pour la première version jouable. Le document compagnon `2026-09-12-industrial-economy-recipes.txt` conserve la proposition complète.

Le catalogue actuel contient trois recettes et deux installations. Le moteur exécute déjà un lot par installation en parallèle et poursuit les travaux hors ligne. Il ne gère pas encore les rendements multiples, le verrouillage des recettes par profondeur, les nouvelles matières premières ni la migration vers un catalogue étendu.

## Approche recommandée

Intégrer un catalogue complet piloté par les données, puis connecter les six installations et les grands paliers à ce catalogue. Conserver les identifiants des trois recettes existantes et les stocks des parties actuelles. Ajouter des tests de progression et une estimation de la durée des chaînes avant d’ajuster les valeurs.

Deux alternatives ont été évaluées : ajouter uniquement les recettes sans changer la progression laisserait les équipements avancés sans utilité ; réécrire toute la simulation accroîtrait les risques sur les sauvegardes et le hors ligne sans être nécessaire. L’extension ciblée du moteur existant répond à la proposition.

## Six installations

| Identifiant | Nom affiché | Déblocage proposé |
| --- | --- | --- |
| furnace | Fonderie | Surface |
| workshop | Atelier | Surface |
| machining | Usinage | 30 m |
| crystal_lab | Laboratoire cristallin | 90 m |
| electronics | Électronique | 90 m |
| chemistry | Chimie | 150 m |

« Cristallurgie » dans les tableaux désigne le Laboratoire cristallin, et ne constitue pas un septième bâtiment. Chaque installation possède un emplacement de production ; les six peuvent travailler en parallèle. Les améliorations augmentant leur vitesse ou leur nombre d’emplacements feront l’objet de l’équilibrage suivant, sans introduire de coûts arbitraires dans cette première intégration.

## Déblocages

| Zone | Profondeur de déblocage | Recettes | Nouvelle extraction |
| --- | --- | --- | --- |
| 1 | 0 m | 1–10 | Fer, charbon, cuivre existants |
| 2 | 30 m | 11–20 | — |
| 3 | 60 m | 21–30 | Silice |
| 4 | 90 m | 31–40 | Cristal via cavités existantes |
| 5 | 150 m | 41–50 | Bauxite et soufre |
| 6 | 240 m | 51–60 | Nickel |
| 7 | 360 m | 61–70 | Tungstène et cobalt |
| 8 | 500 m | 71–80 | Lithium et titane |
| 9 | 700 m | 81–90 | Terres rares |
| 10 | 1 000 m | 91–100 | Fragments via structures anciennes |

Les nouvelles matières minérales doivent être garanties à l’entrée de leur zone, avec une extraction améliorable dans l’écran Industrie. Leur obtention ne dépend pas d’un tirage aléatoire qui pourrait bloquer la chaîne principale. Les fragments restent liés à l’exploration des structures anciennes : une structure accessible est garantie à 1 000 m, son ouverture donne accès à des opérations de récupération relançables. Aucune récompense de fragments n’est attribuée deux fois pour une même opération, y compris après chargement hors ligne. Les structures historiques à 120 m restent présentes ; la récupération avancée se débloque à 1 000 m.

## Progression par équipements

Les pas de forage restent de 10 m. Les transitions majeures consomment des équipements disponibles dans la zone que le joueur quitte, et débloquent les recettes de la zone suivante après leur achèvement. Le Centre conserve son rôle de capacité ; les composants industriels remplacent progressivement ses coûts et ceux des améliorations de forage.

| Transition cible | Équipements proposés pour la première intégration |
| --- | --- |
| 30 m | Châssis mécanique |
| 60 m | Tête de forage I et treuil |
| 90 m | Tête de forage II et module de ventilation |
| 150 m | Contrôleur de forage I et scanner profond |
| 240 m | Tête de forage III et module de refroidissement |
| 360 m | Entraînement d’ascenseur et moteur industriel |
| 500 m | Groupe de forage profond |
| 700 m | Tête de forage IV et batterie haute densité |
| 1 000 m | Module de forage autonome et noyau de commande profond |
| 1 500 m | Excavateur autonome ; cœur abyssal comme objectif final de fabrication |

Cette table définit l’utilité et l’ordre des équipements, pas un équilibrage final. Aucun seuil ne demande une recette débloquée après ce seuil. Une tête ou un équipement déjà installé conserve son effet : les pas intermédiaires n’en consomment pas un nouvel exemplaire à chaque forage. Les anciens niveaux de foreuse sont migrés vers les équipements déjà acquis sans reprendre la profondeur au joueur.

## Recettes et rendements

Chaque recette décrit ses ingrédients, l’installation, la profondeur minimale, la durée d’un lot, le produit et le rendement par lot. « Fil ×4 » signifie quatre fils pour le coût et le temps indiqués ; lancer trois lots donne douze fils et prend trois fois le temps. Le nombre de lots reste limité à 1–10 comme aujourd’hui.

Les abréviations sont normalisées explicitement : Verre → verre industriel ; Moteur → moteur simple ; Servo → servomoteur ; Contrôleur → contrôleur de forage I ; Inox → acier inoxydable ; Refroidissement → module de refroidissement ; Navigation → noyau de navigation. Dans les recettes d’alliage et de composants avancés, Nickel, Cobalt, Tungstène et Titane désignent leurs lingots ; les minerais bruts restent les ingrédients des recettes de fonte. « Terre rare » dans le cristal résonant désigne le concentré de terres rares. Ces choix sont à confirmer lors de la relecture, car les noms abrégés du tableau peuvent avoir plusieurs interprétations.

Un contrôle automatique vérifie que les 100 recettes ont un produit connu, des ingrédients connus, un rendement et une durée positifs, une installation valide et aucune dépendance circulaire. Il vérifie également l’accessibilité de leurs ingrédients à leur profondeur de déblocage.

## Interface

L’écran Industrie affiche les six bâtiments, leurs déblocages, les lots en cours et les recettes regroupées par zone. Une recherche et un filtre « accessibles » évitent de parcourir cent options dans un menu déroulant. Chaque fiche montre le rendement exact, les ingrédients détenus/requis et la durée. Les ressources secondaires sont consultables dans un inventaire dédié ; le HUD portrait reste compact. Les interactions utilisent au moins 44 pixels logiques et le style visuel livré est conservé.

## Sauvegardes et vérification

Une version de sauvegarde 3 migre les versions 1 et 2 après validation de leur structure historique. Elle ajoute les nouveaux stocks à zéro, conserve les ressources, la profondeur, les sites, les événements et les travaux en cours. Les lots historiques déjà payés gardent leur durée et leur rendement d’origine ; le joueur ne perd ni son lot ni ses ingrédients. Les déblocages correspondant à la profondeur déjà atteinte sont attribués de manière idempotente.

La simulation doit produire les mêmes résultats après une absence que par avancement découpé, y compris avec plusieurs installations et récupération de fragments. Les tests couvrent les rendements multiples, les blocages de profondeur, les paiements atomiques, la migration et un parcours sans blocage jusqu’à 1 500 m. Les écrans Industrie et inventaire sont contrôlés avec captures en portrait.

## Cadence et ordre de réalisation

Les durées proposées, y compris les recettes finales de plusieurs heures, remplacent pour cette extension les anciennes limites de la v0.3. Elles ne constituent pas une promesse de durée totale jusqu’à 500 ou 1 000 m : cette durée dépend également des rendements miniers et des productions parallèles.

1. Catalogue complet, rendements et migration de sauvegardes.
2. Six bâtiments, inventaire et consultation des recettes.
3. Extraction des nouvelles ressources, récupération de fragments et progression par équipements.
4. Parcours de validation et mesure des durées pour le futur équilibrage.

Travail sur une branche dédiée à l’économie après validation de cette conception ; aucune fusion dans `main` sans demande du joueur. Les assets de la direction artistique sont conservés.
