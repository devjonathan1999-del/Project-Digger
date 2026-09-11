# Project Digger — Visual Depth v0.5 Design

**Date:** 2026-09-11  
**Branch:** `feature/visual-depth-v0.5`  
**Base:** `main` at `5953b67ac231ec16049c3e9018f74200dcccb9ec`

## Goal

Transformer la Mine v0.4, actuellement lisible mais encore très « schéma industriel », en un véritable complexe minier souterrain crédible et varié.

La v0.5 est exclusivement une évolution de **world building visuel**. Elle ne modifie ni l'économie, ni les timers, ni la progression, ni les sauvegardes, ni la navigation principale.

## Constraints

- `IndustryGame` et `IndustrySession` restent inchangés.
- Aucun coût, rendement, timer ou palier de progression n'est modifié.
- Le format de sauvegarde reste inchangé.
- HUD compact v0.4 conservé.
- Navigation basse `Mine / Industrie / Centre / Technologie` conservée.
- Les zones tactiles et actions contextuelles existantes restent fonctionnelles.
- Le rendu reste en lecture seule vis-à-vis du modèle.
- Le résultat doit rester reproductible : aucune galerie ne change de forme à chaque frame ou après rechargement.
- Godot 4.7.2 / `gl_compatibility` / CI Xvfb restent la cible de validation.

## Approaches considered

### A. Galeries entièrement procédurales

Générer librement formes, fissures et équipements à partir d'un bruit/seed visuel.

**Avantages:** grande variété, extensible.  
**Inconvénients:** risque de rendu incohérent, difficile à contrôler et tester, peut produire des compositions illisibles.

### B. Scènes graphiques fabriquées à la main

Créer plusieurs scènes/assets séparés pour chaque galerie, surface, puits et profondeur.

**Avantages:** contrôle artistique maximal.  
**Inconvénients:** coût de production élevé, beaucoup d'assets à maintenir, disproportionné pour le prototype actuel.

### C. Modules déterministes semi-procéduraux — retenu

Utiliser un petit catalogue de profils visuels conçus à la main, puis sélectionner et varier ces profils de manière déterministe selon la profondeur, le côté et le type d'élément.

**Avantages:** variété visible, cohérence artistique, tests simples, aucune sauvegarde supplémentaire, compatible avec le renderer procédural existant.  
**Inconvénient:** variété finie, mais suffisante pour la v0.5.

## Architecture

### `MineVisualLayout` — nouveau composant pur

Créer `src/industry/ui/mine_visual_layout.gd`.

Responsabilité unique : produire des profils visuels déterministes sans dessiner et sans accéder au gameplay.

Entrées typiques :

- profondeur d'un horizon ;
- côté gauche/droite ;
- profondeur totale atteinte ;
- niveau du Centre.

Sorties : dictionnaires de présentation tels que :

- `gallery_variant` ;
- largeur/hauteur visuelle ;
- renfoncements ;
- portions de rail actives/cassées ;
- densité de supports ;
- lampes présentes/absentes ;
- machines décoratives ;
- ventilation/tuyaux ;
- profil de roche local.

La sélection doit être stable pour une même paire `(depth, side)`.

### `MineSceneRenderer`

Reste responsable du dessin final mais délègue la décision de composition à `MineVisualLayout`.

Le renderer gagne quatre ensembles visuels :

1. surface minière identifiable ;
2. puits central détaillé ;
3. galeries asymétriques et variées ;
4. géologie et atmosphère de profondeur.

### `MineInteractionPresenter`

Conserve les mêmes zones tactiles invisibles.

Les libellés deviennent moins « UI » :

- une balise minimale reste disponible ;
- le texte complet est mis en avant au survol ou lorsque l'élément est sélectionné ;
- découvertes profondes et sites permanents peuvent conserver un accent cyan discret ;
- aucun gros cartouche permanent n'est réintroduit.

## 1. Gallery variety

Le renderer dispose d'au moins **six profils de galerie** :

1. `standard` — galerie industrielle régulière ;
2. `narrow` — hauteur réduite, renforts plus serrés ;
3. `wide` — grande cavité avec machines ou stockage ;
4. `collapsed` — interruption partielle des rails et amas rocheux ;
5. `alcove` — renfoncement latéral technique ou minéral ;
6. `dead_end` — branche courte ou galerie partiellement condamnée.

Les profils modifient réellement :

- longueur visible ;
- hauteur de cavité ;
- nombre et position des supports ;
- lampes ;
- rails ;
- tuyauterie ;
- caisses/machines/ventilation ;
- silhouette de la roche autour de la galerie.

Deux horizons successifs ne doivent pas présenter systématiquement la même silhouette des deux côtés.

## 2. Central shaft

Le puits devient l'élément structurel principal de l'écran.

Il comprend :

- cage d'ascenseur visible ;
- deux câbles principaux ;
- contrepoids visuel ;
- conduites techniques verticales ;
- plateformes aux jonctions des horizons ;
- traverses et renforts ;
- éclairages de sécurité ;
- raccordements lisibles vers les galeries ;
- front de taille/foreuse clairement connecté à la base du puits.

L'ascenseur et les éléments mobiles restent purement décoratifs et reflètent uniquement l'animation existante.

## 3. Surface mining base

La surface v0.4 est conservée mais enrichie pour rendre les fonctions immédiatement identifiables.

Éléments minimum :

- chevalement central ;
- atelier avec toiture et porte technique ;
- silo/stockage ;
- centre d'opérations ;
- ventilation industrielle ;
- conduites extérieures ;
- éclairages ;
- modules supplémentaires selon le niveau du Centre (grue, antenne, réseau technique).

Le rendu doit être asymétrique et éviter l'effet « quatre rectangles alignés ».

## 4. Geology and depth

Les grands aplats deviennent une vraie masse rocheuse stylisée.

Chaque zone peut inclure :

- strates irrégulières ;
- fissures ;
- blocs/éboulis ;
- arêtes et cassures ;
- petites cavités ;
- inclusions minérales ;
- ombres locales autour des galeries et du puits.

Palette :

- 0–60 m : roche gris chaud / acier / ambre ;
- 60–90 m : roche plus dense, luminosité réduite ;
- 90–120 m : premiers accents cyan et inclusions inhabituelles ;
- 120–150 m : cyan/turquoise plus marqué, cristaux et cavités ;
- 150 m+ : ambiance froide et mystérieuse, sans basculer dans le néon généralisé.

Les détails géologiques doivent être déterministes par tranche de profondeur.

## 5. World markers

Les noms `Fer`, `Charbon`, `Cuivre`, `Foreuse`, `Signal minéral` ne doivent plus dominer la composition.

Comportement retenu :

- état normal : petite balise/pictogramme + texte très discret ;
- hover/focus : libellé lisible à pleine opacité ;
- sélection : libellé accentué tant que le panneau contextuel concerne cet élément ;
- sites permanents : cyan discret ;
- foreuse : ambre/cuivre ;
- minerais principaux : ton neutre industriel.

Les boutons tactiles restent invisibles et conservent leurs noms/nœuds actuels pour les tests et les interactions.

## 6. Determinism and presentation state

Aucune nouvelle donnée n'est persistée.

Les choix visuels dérivent uniquement de valeurs existantes :

- profondeur de l'horizon ;
- côté gauche/droite ;
- profondeur totale atteinte ;
- niveau du Centre ;
- découvertes/sites existants.

Exemple de clé déterministe : `depth * 31 + side_index * 17`.

Le renderer ne doit jamais appeler une API de mutation de `IndustryGame` ou `IndustrySession`.

## Testing strategy

### Headless/pure tests

Ajouter des tests sur `MineVisualLayout` :

- même `(depth, side)` => même profil ;
- plusieurs horizons => plusieurs variantes observables ;
- profils retournés valides ;
- absence de données gameplay mutées.

### UI/world tests

Ajouter `tests/test_visual_v05_world.gd` pour vérifier :

- au moins quatre variantes distinctes sur un scénario profond ;
- puits avec cage/câbles/plateformes/conduites ;
- surface avec plusieurs silhouettes fonctionnelles ;
- géologie détaillée dans au moins trois zones ;
- détails profonds plus cyan à 150 m qu'à 30 m ;
- zones tactiles existantes toujours présentes.

### Marker tests

Ajouter `tests/test_visual_v05_markers.gd` :

- balises faibles au repos ;
- libellé renforcé au hover/focus simulé ;
- sélection garde le marqueur accentué ;
- aucun bouton tactile opaque ne réapparaît.

### Regression

Tous les tests v0.1 à v0.4 restent verts.

Le test de non-mutation du rendu reste obligatoire.

## Capture matrix

Publier dans l'artefact `industry-ui` au minimum :

- `v05-wide-60m.png` ;
- `v05-wide-150m.png` ;
- `v05-narrow-90m.png` ;
- `v05-wide-selected.png`.

Les captures doivent permettre de contrôler :

- variété des galeries ;
- richesse du puits ;
- progression géologique ;
- intégration des marqueurs ;
- conservation du HUD/nav v0.4.

## Acceptance criteria

La v0.5 est acceptée si :

1. une capture ne donne plus l'impression de six galeries copiées-collées ;
2. le puits central ressemble à une infrastructure complète et non à deux traits verticaux ;
3. la surface se lit comme une base minière ;
4. la roche possède une vraie texture visuelle stylisée ;
5. la profondeur modifie clairement l'ambiance ;
6. les marqueurs ne ressemblent plus à des labels UI flottants permanents ;
7. les interactions v0.4 restent intactes ;
8. aucune règle de gameplay ni sauvegarde n'est modifiée ;
9. tous les tests et captures CI sont verts.

## Out of scope

- nouveaux assets bitmap/3D lourds ;
- système de biome gameplay ;
- nouveaux minerais ;
- nouveaux bâtiments fonctionnels ;
- modification des coûts ou timers ;
- nouvelle sauvegarde ;
- météo ;
- personnages détaillés ;
- particules complexes ;
- refonte du HUD ;
- refonte de la navigation principale.
