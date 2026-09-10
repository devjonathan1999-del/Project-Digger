# Project Digger

Vertical slice v0.1 d'un jeu 2D en coupe verticale centré sur la manipulation du sous-sol.

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
godot --headless --path . -s res://tests/test_runner.gd
```

Le runner renvoie `0` si toutes les assertions passent et `1` sinon.

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
