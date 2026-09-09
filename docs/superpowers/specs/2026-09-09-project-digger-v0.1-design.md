# Project Digger — Design v0.1

Date : 2026-09-09
Statut : spécification à valider avant implémentation

## 1. Vision

Project Digger est un jeu 2D en coupe verticale centré sur la manipulation directe du sous-sol. Le joueur ne contrôle pas un mineur : il utilise une technologie ancienne pour creuser, déplacer, fusionner puis, plus tard, transformer la matière afin de progresser toujours plus profondément dans un monde persistant.

Boucle fondamentale :

**Observer → Préparer → Déclencher → Résoudre → Exploiter → Descendre**

Le jeu complet vise une progression longue, linéaire et persistante, avec hubs souterrains, chantiers à timers, réseau ancien, logistique, recherche et nouvelles matières. La v0.1 ne cherche pas encore à prouver cette méta-progression : elle doit d’abord prouver que la manipulation du terrain et les effondrements sont amusants.

## 2. Question à valider avec la v0.1

> Est-ce que creuser, déplacer et fusionner la matière, préparer un effondrement puis déclencher la simulation produit une boucle claire, satisfaisante et suffisamment riche pour porter Project Digger ?

La v0.1 doit être jouable de l’entrée d’une caverne jusqu’à une sortie en profondeur.

## 3. Périmètre jouable

Une grande caverne 2D semi-ouverte comprenant :

1. une zone d’entrée simple ;
2. une zone de roche friable ;
3. un filon de minerai stabilisant ;
4. une masse de roche dense impossible à creuser directement ;
5. un relais ancien à préserver ;
6. un obstacle final qui exige de provoquer une modification structurelle importante ;
7. une sortie vers les profondeurs.

Le passage final doit être ouvert par l’utilisation de la stabilité et d’un effondrement, mais le choix des supports à retirer, des zones à renforcer et de la manière de préserver le réseau reste ouvert au joueur.

## 4. États de jeu

### Observer

Le monde est stable. Le joueur inspecte les matières, la stabilité structurelle et le réseau ancien.

### Préparer

La simulation physique principale est suspendue. Le joueur dispose d’une réserve d’énergie de cycle et peut :

- creuser ;
- déplacer une masse autorisée ;
- fusionner des matières compatibles.

Ces actions modifient un **état préparatoire** et sont annulables tant que le joueur n’a pas déclenché la résolution. Une annulation restitue le coût d’énergie correspondant.

Le jeu affiche une prévision partielle : zones stables, fragiles et critiques, continuité du réseau et risques structurels évidents.

### Déclencher

Le joueur valide l’ensemble de la préparation. L’état préparatoire devient l’état logique courant et ne peut plus être annulé.

### Résoudre

La gravité et les effondrements sont calculés jusqu’à stabilisation ou jusqu’à une limite stricte d’itérations. Les conséquences restent dans le monde.

**Aucune capacité d’urgence n’est incluse dans la v0.1.** Le système pourra être réévalué après les premiers tests de gameplay.

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
- sert d’obstacle structurel et peut tomber si ses supports disparaissent.

### Minerai stabilisant

- ressource fonctionnelle ;
- peut être fusionné avec une matière structurelle ;
- augmente la résistance locale de la zone fusionnée.

## 6. Stabilité structurelle

Chaque cellule solide possède au minimum :

- un type de matière ;
- une masse ;
- une résistance ;
- un état de support ;
- un état de stabilité calculé.

L’interface traduit le résultat en trois états :

- **Stable** ;
- **Fragile** ;
- **Critique**.

La stabilité est déterministe dans la v0.1. À état identique, la résolution doit produire le même résultat. Le joueur doit pouvoir comprendre après coup pourquoi une masse est tombée.

Les effondrements sont des outils de gameplay, pas uniquement des sanctions.

## 7. Terrain

### Représentation interne

Le terrain repose sur une grille de cellules fines. La grille est l’autorité logique pour les matières, la stabilité, les interactions et la sauvegarde.

### Rendu

La grille ne doit pas être visuellement dominante. Un rendu séparé transforme cet état en coupe géologique organique grâce à des contours, textures et transitions.

Cette séparation doit permettre d’ajouter plus tard eau, gaz, chaleur, pression, conductivité avancée et réactions minérales sans remplacer le modèle fondamental du terrain.

## 8. Réseau ancien v0.1

Le réseau est volontairement simplifié :

- un relais ancien ;
- des cellules ou veines conductrices ;
- une continuité binaire **connecté / coupé**.

Il sert à enseigner qu’une modification du terrain peut aussi endommager une infrastructure utile.

Capacité, surcharge, puissance, transport de matière et amplification sont hors périmètre v0.1.

## 9. Énergie de cycle

En Préparer, chaque action valide consomme une énergie abstraite.

Objectifs :

- empêcher le remodelage illimité de la caverne ;
- créer des arbitrages locaux ;
- préfigurer la future économie énergétique.

Une action invalide ne consomme rien. Les coûts sont data-driven et modifiables sans changer la logique des actions.

## 10. Interface

Direction : **sci-fi minéral stylisé**, équilibrant atmosphère et lisibilité.

HUD minimal :

- état actuel ;
- énergie restante ;
- outil actif ;
- état du relais ;
- objectif de profondeur ;
- commande Annuler pendant Préparer ;
- commande Déclencher.

Mode d’analyse en Préparer :

- stabilité ;
- risque d’effondrement ;
- continuité du réseau ;
- prévision partielle.

Les données techniques détaillées ne sont pas affichées en permanence.

## 11. Caméra et contrôles

Vue 2D latérale en coupe verticale.

Pour le prototype :

- navigation caméra clavier/souris ;
- zoom ;
- sélection directe du terrain ;
- commandes pensées pour être adaptables au tactile.

Le support mobile complet n’est pas un objectif v0.1. La couche d’entrée ne doit toutefois pas dépendre exclusivement d’un clic droit, d’un survol ou d’un clavier.

## 12. Sauvegarde

La v0.1 sauvegarde au minimum :

- état validé des cellules ;
- masses déplacées et stabilisées ;
- état du relais ;
- état du cycle ;
- progression jusqu’à la sortie.

Un état préparatoire non déclenché n’a pas besoin d’être restauré après fermeture du jeu : la sauvegarde correspond au dernier état validé.

Le format est versionné dès la première version.

## 13. Architecture logique

### TerrainModel
Autorité sur les cellules et leurs propriétés.

### MaterialCatalog
Définitions data-driven des matières.

### StabilitySystem
Calcule support, stabilité, prévision et résolution structurelle.

### TerrainActions
API unique pour Creuser, Déplacer et Fusionner. Valide les actions et leurs coûts.

### PreparationState
Copie de travail ou journal de modifications représentant les actions non encore déclenchées. Permet l’annulation avant validation.

### SimulationController
Gère Observer / Préparer / Déclencher / Résoudre et orchestre la résolution.

### AncientNetwork
Calcule la continuité du réseau v0.1.

### SaveSystem
Sérialise uniquement l’état logique validé.

### TerrainRenderer
Transforme le TerrainModel en représentation visuelle organique.

### HUD
Présente cycle, énergie, outils, réseau et informations d’analyse.

Les systèmes communiquent par interfaces ou signaux explicites. Aucun composant visuel ne devient l’autorité sur les règles de gameplay.

## 14. Flux principal

1. Chargement du TerrainModel validé.
2. Observer : inspection libre.
3. Passage en Préparer et création du PreparationState.
4. TerrainActions valide et applique les modifications au PreparationState.
5. StabilitySystem produit la prévision partielle.
6. Le joueur peut annuler une ou plusieurs actions.
7. Déclencher valide le PreparationState.
8. SimulationController lance la résolution structurelle déterministe.
9. TerrainModel reçoit le nouvel état stabilisé.
10. AncientNetwork recalcule la continuité.
11. SaveSystem écrit l’état validé.
12. Retour à Observer ou validation de la sortie.

## 15. Règles de robustesse

- Une action invalide n’altère ni terrain ni énergie.
- Une masse impossible à déplacer explique visuellement la cause.
- La résolution possède une limite stricte d’itérations.
- Les sauvegardes sont écrites atomiquement ou via fichier temporaire avant remplacement.
- Une sauvegarde incompatible n’est jamais chargée partiellement en silence.
- Une erreur de rendu ne doit pas modifier l’état logique du terrain.

## 16. Tests v0.1

Tests automatisés prioritaires :

- chargement des définitions de matières ;
- validation et coût des actions ;
- annulation d’une action préparée ;
- calcul de support simple ;
- transitions Stable → Fragile → Critique ;
- effondrement déterministe d’un cas connu ;
- fusion avec minerai stabilisant ;
- continuité puis rupture du réseau ;
- sérialisation/restauration du TerrainModel ;
- transitions du SimulationController.

Tests de jeu manuels :

- comprendre comment ouvrir le passage sans documentation externe ;
- identifier visuellement un risque d’effondrement ;
- réussir volontairement un effondrement ;
- provoquer une erreur et comprendre sa cause ;
- ressentir une utilité distincte pour Creuser, Déplacer et Fusionner ;
- vouloir retenter la caverne avec une autre préparation.

## 17. Critères de réussite

La v0.1 est validée si :

1. Observer → Préparer → Déclencher est compris sans tutoriel lourd ;
2. provoquer un effondrement volontaire est satisfaisant ;
3. les conséquences majeures restent explicables ;
4. préserver ou couper le réseau crée un arbitrage ;
5. Creuser, Déplacer et Fusionner ont chacun une utilité ;
6. le terrain persiste correctement après sauvegarde/rechargement ;
7. la caverne donne envie d’être rejouée avec une autre approche.

Si ces critères ne sont pas remplis, timers, hubs et progression longue ne sont pas développés avant correction du cœur de jeu.

## 18. Hors périmètre v0.1

- timers réels et progression hors ligne ;
- hubs/colonies évolutifs ;
- logistique inter-hubs ;
- raffineries et files de production ;
- eau, gaz, vapeur, chaleur et pression ;
- faune et défenses complexes ;
- génération procédurale complète ;
- PNJ et narration développée ;
- arbres de technologie ;
- capacité d’urgence pendant Résoudre ;
- monétisation ;
- endgame ;
- multijoueur.

## 19. Direction long terme à préserver

L’architecture de la v0.1 ne doit pas empêcher :

- campagne linéaire de longue durée ;
- monde vertical persistant ;
- grandes strates semi-ouvertes ;
- hubs/colonies spécialisés et interconnectés ;
- projets à timers et progression hors connexion ;
- timers bloquant une branche mais jamais tout le jeu ;
- accélération des timers obtenue par le gameplay ;
- nouvelles fonctions plutôt que simples bonus chiffrés ;
- matières cumulatives et réactions émergentes ;
- réseau ancien fragile, limité et dépendant des matériaux ;
- technologie ancienne géométrique fusionnée au monde minéral ;
- évolution visuelle forte des infrastructures ;
- échec local transformant le monde sans reset de campagne.

## 20. Hypothèse de plateforme pour le prototype

Le prototype sera d’abord développé pour ordinateur afin d’itérer rapidement, tout en gardant une couche d’entrée compatible avec une future adaptation tactile/mobile.

Cette hypothèse peut être modifiée sans remettre en cause le TerrainModel, le système de stabilité ou la boucle de simulation.
