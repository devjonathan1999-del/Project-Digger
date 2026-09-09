# Project Digger — Design v0.1

Date : 2026-09-09
Statut : spécification à valider avant implémentation

## 1. Vision

Project Digger est un jeu 2D en coupe verticale centré sur la manipulation directe du sous-sol. Le joueur ne contrôle pas un mineur : il utilise une technologie ancienne pour creuser, déplacer, fusionner et transformer la matière afin de progresser toujours plus profondément dans un monde persistant.

La boucle fondamentale est :

**Observer → Préparer → Déclencher → Résoudre → Exploiter → Descendre**

Le jeu complet visera une progression longue, linéaire et persistante, avec hubs souterrains, chantiers à timers, réseau ancien, logistique, recherche et nouvelles matières. La v0.1 ne cherche pas encore à prouver cette méta-progression : elle doit d’abord prouver que la manipulation du terrain et les réactions sont amusantes.

## 2. Objectif du vertical slice v0.1

Répondre à une seule question :

> Est-ce que creuser, déplacer et fusionner la matière, préparer un effondrement puis déclencher la simulation produit une boucle de jeu claire, satisfaisante et suffisamment riche pour porter Project Digger ?

La v0.1 doit être jouable de l’entrée d’une caverne jusqu’à une sortie en profondeur.

## 3. Périmètre jouable

Une grande caverne 2D semi-ouverte comprenant :

1. une zone d’entrée simple ;
2. une zone de roche friable ;
3. un filon de minerai stabilisant ;
4. une masse de roche dense impossible à creuser directement ;
5. un relais ancien à préserver ;
6. un obstacle final résolu par effondrement contrôlé ;
7. une sortie vers les profondeurs.

Le joueur doit pouvoir trouver plusieurs manières raisonnables d’aborder l’obstacle final, mais la v0.1 n’a pas besoin d’un bac à sable intégral.

## 4. États de jeu

### Observer

Le monde est stable et lisible. Le joueur inspecte les matières, la stabilité structurelle et le réseau ancien.

### Préparer

La simulation principale est suspendue. Le joueur dépense une réserve d’énergie de cycle pour :

- creuser ;
- déplacer une masse ;
- fusionner des matières compatibles.

Le jeu affiche une prévision partielle : zones stables, fragiles et critiques, continuité du réseau et risques évidents.

### Déclencher

Le joueur valide sa préparation. La simulation reprend pour une courte résolution automatique.

### Résoudre

La gravité et les effondrements sont calculés. Les éléments mobiles se stabilisent. Les conséquences restent dans le monde.

La v0.1 peut inclure une seule commande d’urgence expérimentale, par exemple « Stabiliser », uniquement si elle améliore réellement la boucle lors des tests.

## 5. Matières v0.1

### Roche commune

- creusable ;
- résistance moyenne ;
- matériau structurel de base.

### Roche friable

- facile à creuser ;
- faible stabilité ;
- favorise les effondrements.

### Roche dense

- non creusable avec l’outil initial ;
- forte masse ;
- utilisée comme obstacle et projectile structurel.

### Minerai stabilisant

- ressource fonctionnelle ;
- peut être fusionnée avec une matière structurelle ;
- augmente la stabilité de la zone concernée.

## 6. Stabilité structurelle

Chaque cellule solide possède au minimum :

- un type de matière ;
- une masse ;
- une résistance ;
- un état de support ;
- un état de stabilité calculé.

L’interface traduit la complexité en trois états :

- **Stable** ;
- **Fragile** ;
- **Critique**.

La stabilité doit être déterministe dans la v0.1. Le joueur doit pouvoir comprendre après coup pourquoi une masse est tombée.

Les effondrements sont des outils de gameplay, pas uniquement des sanctions.

## 7. Terrain

### Représentation interne

Le terrain repose sur une grille de cellules relativement fines. La grille est l’autorité logique pour les matières, la stabilité, les interactions et la sauvegarde.

### Rendu

La grille ne doit pas être visuellement dominante. Le rendu utilise des contours, textures et transitions pour donner une apparence organique de coupe géologique.

Cette séparation permet d’ajouter ultérieurement :

- eau ;
- gaz ;
- chaleur ;
- pression ;
- conductivité avancée ;
- réactions chimiques/minérales.

sans remplacer le modèle fondamental du terrain.

## 8. Réseau ancien v0.1

Le vertical slice contient un réseau simplifié :

- un relais ancien ;
- des cellules ou veines conductrices ;
- une continuité binaire connecté / coupé.

Le réseau sert à enseigner que détruire le terrain peut également détruire une infrastructure utile.

La capacité, surcharge, puissance et transport de matière sont hors périmètre v0.1.

## 9. Énergie de cycle

En phase Préparer, chaque action consomme une énergie abstraite.

Objectifs :

- empêcher le joueur de remodeler toute la caverne sans arbitrage ;
- créer des décisions locales ;
- préfigurer la future économie énergétique.

Les valeurs exactes sont des paramètres de gameplay et doivent rester faciles à modifier.

## 10. Interface

Direction : **sci-fi minéral stylisé**, équilibrant atmosphère et lisibilité.

HUD minimal :

- état actuel : Observer / Préparer / Déclencher ;
- énergie restante ;
- outil actif ;
- état du relais ;
- objectif de profondeur.

Mode d’analyse en Préparer :

- stabilité ;
- risque d’effondrement ;
- continuité du réseau ;
- prévision partielle.

Les informations techniques détaillées ne sont pas affichées en permanence.

## 11. Caméra et contrôles

Vue 2D latérale en coupe verticale.

Pour le prototype :

- navigation caméra au clavier/souris ;
- zoom ;
- sélection directe du terrain ;
- gestes conçus de façon à pouvoir être adaptés au tactile plus tard.

Le support mobile complet n’est pas un objectif v0.1 ; l’architecture d’entrée ne doit toutefois pas dépendre exclusivement d’un clic droit, d’un survol ou d’un clavier.

## 12. Sauvegarde

La v0.1 sauvegarde au minimum :

- état de chaque cellule modifiée ;
- position des masses déplacées ;
- état du relais ;
- énergie ou état de cycle pertinent ;
- progression jusqu’à la sortie.

Format versionné dès le départ pour permettre l’évolution du modèle de données.

## 13. Architecture logique proposée

### TerrainModel

Autorité sur les cellules et leurs propriétés.

### MaterialCatalog

Définitions data-driven des matières. Les nouvelles matières doivent pouvoir être ajoutées sans modifier le cœur du moteur de terrain.

### StabilitySystem

Calcule les supports, zones fragiles et effondrements potentiels.

### TerrainActions

API unique pour Creuser, Déplacer et Fusionner. Les coûts d’énergie sont centralisés ici.

### SimulationController

Gère les états Observer / Préparer / Déclencher / Résoudre et orchestre la résolution.

### AncientNetwork

Calcule la continuité du réseau v0.1.

### SaveSystem

Sérialise l’état logique, indépendamment du rendu.

### TerrainRenderer

Transforme l’état logique de la grille en représentation visuelle organique.

### HUD

Affiche l’état du cycle, l’énergie, l’outil, le réseau et les informations d’analyse.

Les systèmes communiquent par interfaces/signaux explicites ; aucun système visuel ne doit devenir l’autorité sur les règles de gameplay.

## 14. Flux principal

1. Chargement de la caverne et de son TerrainModel.
2. Observer : lecture libre.
3. Passage en Préparer.
4. TerrainActions modifie l’état préparatoire et consomme l’énergie.
5. StabilitySystem produit la prévision partielle.
6. Déclencher valide l’état préparé.
7. SimulationController exécute la résolution.
8. TerrainModel devient le nouvel état persistant.
9. AncientNetwork recalcule la continuité.
10. Sauvegarde.
11. Retour à Observer ou validation de la sortie.

## 15. Gestion des erreurs et règles de sécurité gameplay

- Une action invalide ne consomme pas d’énergie.
- Une masse impossible à déplacer indique clairement pourquoi.
- Le joueur ne peut pas déclencher un état corrompu ou incomplet.
- Une simulation doit avoir une limite stricte d’itérations pour éviter une boucle infinie d’effondrements.
- Les sauvegardes sont écrites de manière atomique ou via fichier temporaire avant remplacement.
- En cas de sauvegarde incompatible, le jeu ne doit pas silencieusement charger des données partielles.

## 16. Tests v0.1

Tests automatisés prioritaires :

- définition et chargement des matières ;
- coût et validation des actions ;
- calcul de support simple ;
- transition Stable → Fragile → Critique ;
- effondrement déterministe d’un cas connu ;
- fusion avec minerai stabilisant ;
- continuité / rupture du réseau ;
- sérialisation puis restauration du TerrainModel ;
- transitions d’état de SimulationController.

Tests de jeu manuels :

- comprendre comment ouvrir le passage sans explication externe ;
- identifier visuellement un risque d’effondrement ;
- réussir volontairement un effondrement ;
- provoquer une erreur et comprendre sa cause ;
- ressentir une différence utile entre creuser, déplacer et fusionner.

## 17. Critères de réussite

La v0.1 est validée si :

1. la boucle Observer → Préparer → Déclencher est compréhensible ;
2. provoquer un effondrement volontaire est satisfaisant ;
3. le joueur peut expliquer les conséquences majeures de ses actions ;
4. préserver ou couper le réseau crée un vrai arbitrage ;
5. Creuser, Déplacer et Fusionner ont chacun une utilité ;
6. l’état du terrain persiste correctement après sauvegarde/rechargement ;
7. le prototype donne envie de rejouer la caverne avec une autre approche.

Si ces critères ne sont pas remplis, les systèmes de timers, hubs et progression longue ne doivent pas être développés avant correction du cœur de jeu.

## 18. Hors périmètre v0.1

Explicitement reportés :

- timers réels et progression hors ligne ;
- colonies/hubs évolutifs ;
- logistique inter-hubs ;
- raffineries et files de production ;
- eau, gaz, vapeur, chaleur et pression ;
- faune et défenses complexes ;
- génération procédurale complète ;
- PNJ et narration développée ;
- arbres de technologie ;
- monétisation ;
- endgame ;
- multijoueur.

## 19. Direction long terme à préserver

Même si la v0.1 est volontairement réduite, son architecture ne doit pas empêcher la vision validée :

- campagne linéaire de longue durée ;
- monde vertical persistant ;
- grandes strates semi-ouvertes ;
- hubs/colonies spécialisés et interconnectés ;
- projets à timers avec progression hors connexion ;
- aucune attente bloquant tout le jeu ;
- nouveaux pouvoirs principalement fonctionnels plutôt que bonus chiffrés ;
- matières cumulatives et réactions émergentes ;
- technologie ancienne géométrique fusionnée au monde minéral ;
- progression visuelle forte des infrastructures ;
- échec local transformant le monde sans reset de campagne.

## 20. Hypothèse à confirmer pendant le prototype

Le prototype sera développé d’abord pour ordinateur afin d’itérer rapidement, tout en gardant une couche d’entrée compatible avec une future adaptation tactile/mobile.

Cette hypothèse peut être changée sans remettre en cause le modèle de terrain ou les règles du vertical slice.
