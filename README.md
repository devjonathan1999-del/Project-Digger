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
xvfb-run -a godot --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_industry_ui.gd -- --screenshots /tmp/digger-v03-ui
```

La CI ajoute également des parcours dédiés aux actions contextuelles, au **Filon instable** et aux états visuels modulaires. Le runner renvoie `0` si toutes les assertions passent et `1` sinon.

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

La couche visuelle est volontairement séparée de l’économie : ascenseur, convoyeurs, wagonnet, petites équipes, foreuse active et sites cristallins reflètent l’état du modèle sans calculer de production ni de récompense.

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
- états visuels modulaires ;
- captures 1280 × 800 et 720 × 1000 publiées dans l’artefact `industry-ui`.

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

### Progression v0.3

- Design : `docs/superpowers/specs/2026-09-10-progression-v0.3-design.md`
- Plan : `docs/superpowers/plans/2026-09-10-progression-v0.3.md`

### Industrie v0.2

- Design : `docs/superpowers/specs/2026-09-10-industry-v0.2-design.md`
- Plan : `docs/superpowers/plans/2026-09-10-industry-v0.2.md`

### Prototype terrain v0.1

- Design : `docs/superpowers/specs/2026-09-09-project-digger-v0.1-design.md`
- Plan : `docs/superpowers/plans/2026-09-09-project-digger-v0.1-implementation.md`
