# Project Digger

Vertical slice v0.2 d'un jeu 2D en coupe verticale centré sur la manipulation tactique du sous-sol.

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

Le runner renvoie `0` si toutes les assertions passent et `1` sinon. La CI vérifie aussi explicitement les erreurs de script/parsing Godot.

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

## v0.2 vertical slice

Project Digger v0.2 conserve la simulation déterministe sur une grille logique **64 × 72**, mais remplace la présentation technique de la v0.1 par la première caverne **Helix**.

- **Observer** : vue de caverne organique, sans grille globale visible.
- **Préparer** : ciblage local, sélection et overlays **Stable / Fragile / Critique**.
- **Outils** : Creuser, Déplacer, Fusionner.
- **Relais ancien** : réseau cyan distinct du terrain ordinaire et état de connexion visible.
- **Résolution** : courte anticipation, impulsion du relais, effondrement animé, poussière, impact caméra proportionnel et audio procédural temporaire.
- **Sauvegarde** : liée à `content_id`; une ancienne sauvegarde v0.1 sans identifiant de contenu ne remplace pas la caverne v0.2.

## Boucle actuelle

1. Observer la caverne et repérer le passage vers les profondeurs.
2. Passer en **Préparer**.
3. Creuser, déplacer ou fusionner avec l'énergie disponible.
4. Lire localement les états **Stable / Fragile / Critique** et l'état du relais.
5. **Déclencher** la résolution.
6. Observer l'effondrement et ses conséquences.
7. Préserver le relais ancien et ouvrir le corridor vers les profondeurs.

Après chaque résolution terminée, le terrain compatible est sauvegardé dans `user://save_v1.json` et rechargé au prochain lancement.

Quand le corridor final est ouvert, le HUD affiche :

`Accès aux profondeurs ouvert — Vertical slice terminé`

## Périmètre v0.2

Inclus : grille logique indépendante du rendu, quatre matériaux, actions réversibles avant déclenchement, stabilité et effondrements déterministes, caverne Helix, rendu organique, analyse contextuelle, relais ancien, HUD compact, feedback visuel/sonore, caméra et sauvegarde/rechargement par contenu.

Hors périmètre : eau, gaz, chaleur, pression avancée, PNJ, timers réels, hubs/colonies, économie/logistique, génération procédurale complexe, minimap et support tactile complet.

## Documentation

- Design v0.2 : `docs/superpowers/specs/2026-09-10-project-digger-v0.2-design.md`
- Plan v0.2 : `docs/superpowers/plans/2026-09-10-project-digger-v0.2-implementation.md`
- Design v0.1 : `docs/superpowers/specs/2026-09-09-project-digger-v0.1-design.md`
- Plan v0.1 : `docs/superpowers/plans/2026-09-09-project-digger-v0.1-implementation.md`
