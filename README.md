# Project Digger

Prototype industriel persistant sous Godot : extraire, transformer, développer une base minière et descendre progressivement jusqu’à **150 m**. La boucle principale combine production courte, préparation industrielle, forage vertical, découvertes latérales et choix d’exploitation.

## Moteur

- Godot **4.7.2 stable**
- GDScript
- Renderer `gl_compatibility`
- Interface native en français

## Lancer le prototype

Ouvrir le dossier dans Godot puis lancer le projet, ou :

```bash
godot --path .
```

## Lancer les tests

Suite logique complète :

```bash
godot --headless --editor --quit --path .
godot --headless --path . -s res://tests/test_runner.gd
```

Parcours UI réel avec rendu OpenGL sous Xvfb :

```bash
xvfb-run -a godot --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_industry_ui.gd -- --screenshots /tmp/digger-ui
```

La CI ajoute également des parcours dédiés aux actions contextuelles, au **Filon instable**, aux états visuels modulaires et aux présentations v0.4/v0.5/v0.6. Le runner renvoie `0` si toutes les assertions passent et `1` sinon.

## Boucle industrielle

Les mines de **fer**, **charbon** et **cuivre** produisent automatiquement. Leur niveau augmente le débit ; chaque tranche de 30 m atteinte augmente la production de base de 15 %. La fonderie et l’atelier travaillent indépendamment, avec un lot actif par installation et des quantités de 1 à 10.

| Installation | Produit | Coût par unité | Durée par unité |
| --- | --- | --- | --- |
| Fonderie | Lingot de fer | 4 fer + 1 charbon | 20 s |
| Fonderie | Lingot de cuivre | 3 cuivre + 1 charbon | 25 s |
| Atelier | Câble | 2 lingots de cuivre + 1 lingot de fer | 40 s |

Le début de partie conserve la boucle courte de v0.2 : produire des lingots, fabriquer du câble, améliorer la foreuse puis ouvrir des chantiers de 10 m. Les mines montent jusqu’au niveau 10 et la foreuse jusqu’au niveau 5.

## Progression verticale v0.3

La progression principale avance par pas de **10 m**, avec cinq grands paliers :

| Profondeur | Progression principale |
| --- | --- |
| 30 m | Premier filon riche garanti, Centre niveau 2 disponible |
| 60 m | Centre niveau 3, foreuse renforcée nécessaire |
| 90 m | Premier point technologique, Centre niveau 4, cavité cristalline garantie |
| 120 m | Nouveau point technologique, Centre niveau 5, structure ancienne garantie |
| 150 m | Zone profonde, Centre niveau 6 et capacité maximale v0.3 |

Les découvertes intermédiaires sont reproductibles à partir de la seed de partie. Elles apparaissent sous forme d’indices comme **Forte signature minérale**, **Cavité instable**, **Anomalie minérale** ou **Structure inconnue**. Les poches épuisables donnent une récompense unique ; les sites permanents restent visibles et peuvent consommer de la capacité d’exploitation.

La **cavité cristalline** ouvre la production de **Cristal brut**, ressource v0.3 utilisée notamment dans les développements avancés.

## Centre et capacité d’exploitation

Le **Centre d’exploitation** progresse du niveau 1 au niveau 6. Sa montée en niveau est liée à la profondeur et augmente la capacité globale disponible.

Les sites permanents utilisent cette capacité lorsqu’ils sont actifs. Le joueur peut les activer ou les désactiver librement tant que la capacité disponible est respectée. Il n’y a pas de gestion séparée d’énergie, de personnel ou de logistique physique : la capacité reste l’unique abstraction de cette contrainte.

## Technologies et priorités

À partir de 90 m, les points technologiques débloquent trois branches :

- **Production** : améliore les débits industriels ;
- **Logistique** : augmente la capacité d’exploitation ;
- **Exploration** : améliore le plancher de qualité des découvertes.

Débloquer une technologie consomme un point technologique, puis sa construction demande des ressources industrielles. Les trois branches restent cumulables ; une seule peut être définie comme **priorité** à la fois pour obtenir un bonus supplémentaire. Le changement de priorité possède un cooldown de 5 minutes et ne peut pas créer un état dépassant la capacité disponible.

## Filon instable

L’exploration d’une **Cavité instable** peut créer un événement **Filon instable**. L’événement reste en attente tant qu’il n’est pas présenté au joueur : son timer ne se consomme donc pas pendant une absence ou avant ouverture.

Une fois présenté, le joueur choisit **Fer**, **Cuivre** ou **Charbon**. La ressource choisie reçoit temporairement un bonus d’extraction pendant 5 minutes. La présentation se fait par une bannière non bloquante dans la vue Mine.

## Navigation et vue Mine

La navigation principale comporte quatre entrées :

- **Mine** : coupe verticale continue, forage, découvertes, sites et accès contextuels ;
- **Industrie** : mines, fonderie et atelier ;
- **Centre** : capacité et gestion des sites permanents ;
- **Technologie** : points, constructions et priorité active.

La vue Mine reste l’écran principal. Elle permet un défilement vertical continu, un zoom limité et des raccourcis de profondeur. Les éléments interactifs ouvrent un panneau contextuel au lieu de transformer la mine en tableau de gestion.

## Présentation visuelle v0.4

La v0.4 ne change **aucune règle économique**. Elle transforme la Mine en scène principale plus proche du jeu final :

- HUD compact regroupant stocks, capacité et profondeur sans grosses cartes permanentes ;
- Mine occupant l’essentiel de la zone de jeu ;
- navigation basse affinée ;
- panneau contextuel flottant sur écran large et **bottom-sheet** sur écran étroit ;
- suppression du panneau permanent de commandes de foreuse ;
- zones tactiles conservées mais rendues quasi invisibles, avec étiquettes courtes intégrées au décor ;
- surface industrielle évolutive avec chevalement, atelier, silo, centre d’opérations, puis grue, antenne et réseau technique selon le niveau du Centre ;
- galeries structurées avec rails, supports, tuyaux, câbles, lampes ambre et modules de machines ;
- foreuse représentée comme une machine au front de taille ;
- progression visuelle des profondeurs : acier/cuivre et lumière ambre au début, puis accents cyan/turquoise, cristaux et anomalies de plus en plus présents à partir des zones profondes.

La direction visuelle cible environ **75 % rétro-futuriste industriel / 25 % sci-fi industriel sobre**. Les effets visuels ne calculent ni production ni récompense : `MineSceneRenderer` reçoit uniquement une copie d’état de présentation et les tests vérifient que plusieurs secondes d’animation ne modifient pas le snapshot économique.

Les captures CI v0.4 couvrent les états **1280×800** et **720×1000**, avec panneau contextuel fermé puis ouvert.

## Profondeur visuelle v0.5

La v0.5 approfondit la scène Mine sans modifier la boucle économique, les coûts, les récompenses ni le schéma de sauvegarde.

- Les galeries utilisent des profils **déterministes semi-procéduraux** selon la profondeur et le côté du puits : largeur, hauteur, supports, lampes, machines, alcôves, voies interrompues, zones élargies, effondrements et culs-de-sac varient sans changer au rechargement.
- Le puits central gagne des plateformes aux horizons principaux, un ascenseur, un contrepoids, des câbles, conduites et liaisons techniques afin de devenir l’axe visuel permanent de la mine.
- La surface devient une base minière identifiable : chevalement, atelier, silo, centre d’opérations, ventilation puis équipements supplémentaires selon le niveau du Centre.
- La roche n’est plus composée uniquement de bandes plates : strates segmentées, fissures, blocs, éboulis, petites cavités et inclusions minérales sont générés de façon déterministe.
- La profondeur modifie progressivement l’ambiance : tons neutres/ambre en haut, roche plus sombre vers 60–90 m, puis cyan et turquoise de plus en plus présents à partir de 90 m sans transformer l’ensemble en décor néon.
- Les marqueurs Fer/Charbon/Cuivre, Foreuse, découvertes et sites restent discrets au repos. Ils sont renforcés au survol, au focus ou lors d’une sélection, puis reviennent à leur état discret lorsque le contexte est fermé.
- Les boutons tactiles réels restent presque invisibles afin de préserver les interactions existantes sans faire revenir l’aspect « gros boutons de debug ».

`MineVisualLayout` fournit les profils de présentation déterministes ; `MineSceneRenderer` les consomme sans écrire dans l’état économique. La v0.5 conserve donc `user://industry_v1.json` et le **schéma interne v2** sans migration supplémentaire.

Les captures CI v0.5 couvrent quatre états déterministes : **1280×800 à 60 m**, **1280×800 à 150 m**, **720×1000 à 90 m** et **1280×800 avec une découverte profonde sélectionnée**.

## Final graphics v0.6

La v0.6 transforme la Mine en une composition hybride proche de la cible graphique finale, toujours sans modifier le gameplay, les coûts, les débits, la progression, les timers, les événements ni le schéma de sauvegarde.

- `MineModuleRenderer` dessine la masse rocheuse, les grandes cavités, les bassins de lumière et les installations industrielles reconnaissables ; `MineFinalModuleRenderer` adapte la même scène aux écrans étroits sans changer les hitboxes.
- Le puits central devient un module héro : structure acier plus large, ascenseur, câbles, rails, contrepoids, conduites et stations aux horizons débloqués.
- La surface est reconstruite comme une vraie base minière avec atelier, silo, chevalement, centre de contrôle, ventilation, réseaux techniques et équipements progressifs du Centre.
- Fer, Charbon, Cuivre et Cristal possèdent des silhouettes et accessoires propres afin d’être identifiables sans dépendre des étiquettes.
- Les ressources graphiques réutilisables sont locales dans `assets/industry/v06/`. Le rendu garde des fallbacks procéduraux et ne dépend d’aucun service réseau à l’exécution.
- La géologie gagne une masse opaque irrégulière, des strates, blocs, fissures, grandes cavités, poussières/vapeur et une progression lumineuse ambre → cyan localisée en profondeur.
- Les cibles tactiles restent autoritatives et atteignent au moins 44 px. Sur écran étroit, les détails tertiaires sont réduits mais les identités de ressources et le panneau contextuel en bottom-sheet restent utilisables.

Les cinq captures CI v0.6 sont déterministes : **surface 1280×800**, **60 m 1280×800**, **150 m 1280×800**, **sélection profonde 1280×800** et **90 m 720×1000**. Elles sont publiées dans l’artefact `industry-ui` avec les captures historiques v0.4/v0.5.

## Sauvegarde et progression hors ligne

La sauvegarde industrielle reste :

```text
user://industry_v1.json
```

Le nom du fichier est conservé pour compatibilité, mais le **schéma interne actuel est v2**. Une sauvegarde v1 issue de la boucle industrielle précédente est migrée automatiquement vers v2 au chargement.

La sauvegarde conserve notamment : stocks, niveaux, profondeur, travaux, Centre, sites permanents, découvertes, explorations, points technologiques, technologies, priorité, événements et seed de partie. Les récompenses de paliers et de découvertes sont idempotentes : recharger plusieurs fois ne les duplique pas.

L’écriture reste atomique via un fichier temporaire. Une sauvegarde invalide est préservée et une erreur est affichée au lieu de l’écraser avec une nouvelle session provisoire.

La production et les travaux continuent pendant l’absence. Au retour, un bilan non bloquant récapitule durée d’absence, ressources produites, travaux terminés et profondeur gagnée. Un événement non encore présenté reste en attente et ne perd pas son temps disponible hors ligne.

L’ancienne sauvegarde du prototype terrain reste séparée dans :

```text
user://save_v1.json
```

## Validation CI

La CI Godot 4.7.2 vérifie notamment :

- import sans `SCRIPT ERROR` ni `ERROR:` ;
- suites logiques v0.1, v0.2 et v0.3 ;
- parcours déterministe de progression jusqu’à 150 m ;
- migration de sauvegarde v1 → v2 ;
- sauvegarde invalide préservée ;
- absence de double récompense au rechargement ;
- équivalence gros saut temporel / petits pas ;
- interactions UI réelles ;
- événement stratégique ;
- états visuels modulaires v0.3 ;
- contrat de layout v0.4 ;
- renderer industriel v0.4 et montée progressive des accents profonds ;
- profils déterministes et silhouettes de galeries v0.5 ;
- enrichissement du puits, de la surface et de la géologie avec la profondeur ;
- marqueurs contextuels v0.5 au repos, focus et sélection, y compris retour au repos à la fermeture du contexte ;
- modules industriels, identités Fer/Charbon/Cuivre/Cristal, géologie finale et responsive v0.6 ;
- zones tactiles invisibles mais réellement cliquables ;
- absence de mutation économique par le rendu ;
- captures wide/narrow v0.4, quatre scénarios v0.5 et cinq scénarios v0.6 publiés dans l’artefact `industry-ui`.

Les captures CI utilisent un vrai rendu OpenGL sous Xvfb. Aucun test Windows ou Android n’est revendiqué à ce stade.

## Prototype terrain v0.1 conservé

La scène `scenes/vertical_slice.tscn` reste disponible directement dans l’éditeur (ouvrir la scène puis F6). Elle correspond à l’ancien prototype de manipulation du terrain et n’est plus la boucle principale de Project Digger.

### Contrôles v0.1

- **Flèches / WASD** : déplacer la caméra
- **Molette** : zoomer / dézoomer
- **Bouton milieu + glisser** : déplacer librement la caméra
- **1** : Creuser
- **2** : Déplacer
- **3** : Fusionner
- **Clic gauche** : utiliser l’outil actif
- **Espace** : passer en Préparer
- **Entrée** : Déclencher
- **Ctrl+Z** : Undo
- **Échap** : Annuler la préparation

### Boucle v0.1

1. Observer la caverne.
2. Passer en **Préparer**.
3. Creuser, déplacer ou fusionner avec l’énergie disponible.
4. Lire les états **Stable / Fragile / Critique**.
5. **Déclencher** la résolution.
6. Laisser les effondrements se résoudre.
7. Préserver le relais ancien et ouvrir le corridor vers les profondeurs.

Quand le corridor final est ouvert, le HUD affiche :

`Accès aux profondeurs ouvert — Vertical slice terminé`

## Documentation

### Final graphics v0.6

- Design : `docs/superpowers/specs/2026-09-11-final-graphics-v0.6-design.md`
- Plan : `docs/superpowers/plans/2026-09-11-final-graphics-v0.6.md`

### Profondeur visuelle v0.5

- Design : `docs/superpowers/specs/2026-09-11-visual-depth-v0.5-design.md`
- Plan : `docs/superpowers/plans/2026-09-11-visual-depth-v0.5.md`

### Présentation visuelle v0.4

- Design : `docs/superpowers/specs/2026-09-11-visual-v0.4-design.md`
- Plan : `docs/superpowers/plans/2026-09-11-visual-v0.4.md`

### Progression v0.3

- Design : `docs/superpowers/specs/2026-09-10-progression-v0.3-design.md`
- Plan : `docs/superpowers/plans/2026-09-10-progression-v0.3.md`

### Industrie v0.2

- Design : `docs/superpowers/specs/2026-09-10-industry-v0.2-design.md`
- Plan : `docs/superpowers/plans/2026-09-10-industry-v0.2.md`

### Prototype terrain v0.1

- Design : `docs/superpowers/specs/2026-09-09-project-digger-v0.1-design.md`
- Plan : `docs/superpowers/plans/2026-09-09-project-digger-v0.1-implementation.md`
