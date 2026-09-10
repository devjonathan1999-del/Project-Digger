# Project Digger

Prototype industriel jouable : extraire en continu, transformer les minerais et renforcer une foreuse pour atteindre de nouveaux horizons. Interface native en français, avec coupe du sous-sol et progression persistante.

## Moteur

- Godot **4.7.2 stable**
- GDScript
- Renderer `gl_compatibility`

## Lancer le prototype

Ouvrir le dossier dans Godot puis lancer le projet, ou :

```bash
godot --path .
```

## Lancer les tests

```bash
godot --headless --editor --quit --path .
godot --headless --path . -s res://tests/test_runner.gd
godot --headless --path . -s res://tests/test_industry_ui.gd
```

Le runner renvoie `0` si toutes les assertions passent et `1` sinon.

## Boucle industrielle

Les mines de **fer**, **charbon** et **cuivre** produisent automatiquement. Leur niveau augmente le débit ; chaque palier de 30 mètres apporte un bonus de 15 % au débit de base. La fonderie et l'atelier travaillent indépendamment, avec un lot actif par installation et des quantités de 1 à 10.

| Installation | Produit | Coût par unité | Durée par unité |
| --- | --- | --- | --- |
| Fonderie | Lingot de fer | 4 fer + 1 charbon | 20 s |
| Fonderie | Lingot de cuivre | 3 cuivre + 1 charbon | 25 s |
| Atelier | Câble | 2 lingots de cuivre + 1 lingot de fer | 40 s |

Premier parcours :

1. Dans la **Fonderie**, choisir le fer, régler la quantité à **3**, puis lancer le lot (60 s).
2. Choisir le cuivre, quantité **2**, puis lancer le lot (50 s).
3. Dans l'**Atelier**, fabriquer **1 câble** (40 s).
4. **Améliorer la foreuse**, puis **Ouvrir le chantier** pour atteindre −10 m.
5. Quitter et rouvrir : les stocks ont progressé et les travaux lancés ont continué pendant l'absence.

Cette préparation initiale de 2 min 30 est un réglage provisoire pour tester la boucle, pas un rythme de rétention de production garanti. Les mines et la foreuse peuvent être améliorées jusqu'aux niveaux 10 et 5. La progression n'est jamais réinitialisée et l'absence n'entraîne aucune pénalité.

La sauvegarde industrielle dédiée est `user://industry_v1.json`. Elle conserve stocks, niveaux, profondeur et travaux en cours, avec sauvegarde automatique toutes les dix secondes et après les actions. Un bilan non bloquant apparaît après au moins cinq secondes d'absence. Une sauvegarde invalide est préservée et une erreur est affichée. L'ancienne sauvegarde de terrain reste séparée dans `user://save_v1.json`.

L'écran s'empile sous 1 000 pixels de largeur et défile verticalement. Les captures graphiques CI (1280 × 800 et 720 × 1000) sont produites avec un vrai rendu OpenGL sous Xvfb, puis publiées dans l'artefact `industry-ui`. Les tests headless seuls ne prouvent pas la qualité visuelle. Aucun test Windows ou Android n'est revendiqué.

## Prototype terrain conservé

La scène `scenes/vertical_slice.tscn` reste disponible directement dans l'éditeur (ouvrir la scène puis F6). Les contrôles et règles ci-dessous concernent cette ancienne scène.

## Contrôles

- **Flèches / WASD** : déplacer la caméra
- **Molette** : zoomer / dézoomer
- **Bouton milieu + glisser** : déplacer librement la caméra
- **1** : Creuser
- **2** : Déplacer
- **3** : Fusionner
- **Clic gauche** : utiliser l'outil actif
- **Espace** : passer en Préparer
- **Entrée** : Déclencher
- **Ctrl+Z** : Undo
- **Échap** : Annuler la préparation

## Boucle v0.1

1. Observer la caverne.
2. Passer en **Préparer**.
3. Creuser, déplacer ou fusionner avec l'énergie disponible.
4. Lire les états **Stable / Fragile / Critique**.
5. **Déclencher** la résolution.
6. Laisser les effondrements se résoudre.
7. Préserver le relais ancien et ouvrir le corridor vers les profondeurs.

Après chaque résolution terminée, le terrain est sauvegardé dans `user://save_v1.json`. La sauvegarde est rechargée au prochain lancement.

La nouvelle sauvegarde est écrite dans un fichier temporaire voisin avant de remplacer la précédente. Si cette écriture ou le remplacement échoue, la dernière sauvegarde validée est conservée ; un fichier temporaire incomplet est ignoré au chargement.

Quand le corridor final est ouvert, le HUD affiche :

`Accès aux profondeurs ouvert — Vertical slice terminé`

## Périmètre v0.1

Inclus :

- grille logique 64 × 72 indépendante du rendu ;
- roche commune, roche friable, roche dense, stabilisant ;
- Creuser / Déplacer / Fusionner ;
- énergie de préparation ;
- Undo et Annuler avant Déclencher ;
- stabilité déterministe ;
- effondrements ;
- relais ancien conducteur ;
- caméra, HUD et analyse visuelle ;
- sauvegarde/rechargement ;
- objectif de sortie.

Hors périmètre :

- eau ;
- gaz ;
- chaleur ;
- pression avancée ;
- PNJ ;
- timers ;
- hubs/colonies ;
- génération procédurale complexe ;
- support tactile complet.

## Documentation

- Design : `docs/superpowers/specs/2026-09-09-project-digger-v0.1-design.md`
- Plan : `docs/superpowers/plans/2026-09-09-project-digger-v0.1-implementation.md`
