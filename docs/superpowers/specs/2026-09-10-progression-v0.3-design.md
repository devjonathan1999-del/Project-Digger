# Project Digger — Progression & Exploration v0.3

Date : 2026-09-10

Base : `feature/industry-v0.2`

## Intention

La v0.2 valide la première boucle industrielle persistante : extraire, transformer, améliorer la foreuse, descendre et retrouver une exploitation qui a continué à travailler. La v0.3 doit transformer cette boucle de prototype en structure de jeu durable.

L'objectif n'est pas de rendre Digger plus idle. Le rythme retenu est **actif** : le joueur doit avoir régulièrement une décision utile à prendre, avec des timers courts au début et modérés ensuite. La durée vient de la succession de paliers, de découvertes, de spécialisations et de développements permanents, pas de temps d'attente artificiellement longs.

La mine elle-même devient l'écran principal du jeu. Le joueur doit voir son exploitation grandir, descendre physiquement dans les profondeurs, retrouver les sites découverts et comprendre l'état de sa production sans passer en permanence par des tableaux de gestion.

## Principes de design

1. **Produire + découvrir.** Chaque cycle de jeu doit faire avancer à la fois l'économie et l'exploration verticale.
2. **Progression linéaire principale.** Le puits principal descend sans embranchement bloquant.
3. **Exploration latérale optionnelle.** Des poches apparaissent sur les côtés du puits et enrichissent la partie sans empêcher la progression principale.
4. **Retours fréquents.** Le joueur revient pour relancer une production, terminer une amélioration, lancer un forage ou répondre à une opportunité.
5. **Pas de punition d'absence.** La production et les travaux continuent hors ligne selon les règles de la v0.2.
6. **Pas de gestion humaine détaillée.** Les équipes existent visuellement et dans le vocabulaire, mais ne deviennent pas une ressource individuelle à gérer.
7. **Lisibilité avant simulation.** Une seule jauge de capacité globale remplace une simulation séparée d'énergie, de personnel et de logistique.
8. **La profondeur doit changer le jeu.** Descendre ne peut pas se résumer à un bonus numérique de rendement.

## Boucle principale

La boucle cible est :

1. observer la mine et les installations actives ;
2. utiliser les ressources produites automatiquement ;
3. lancer ou relancer des fabrications ;
4. choisir entre amélioration industrielle, exploration latérale et préparation du prochain forage ;
5. lancer un forage vers le prochain palier ;
6. atteindre une nouvelle profondeur ;
7. révéler un contenu : ressource, contrainte, site, technologie ou événement ;
8. adapter l'exploitation ;
9. recommencer.

Les fabrications, améliorations et forages doivent pouvoir progresser en parallèle lorsqu'ils utilisent des installations différentes.

## Cadence des timers

La v0.3 cible une expérience active. Les valeurs suivantes sont des **plages d'équilibrage initiales**, pas des constantes définitives :

- premières actions : **20 à 60 secondes** ;
- premières transformations structurantes : **1 à 3 minutes** ;
- progression intermédiaire : **3 à 10 minutes** ;
- opérations importantes plus tardives : **10 à 20 minutes maximum dans cette version**.

Une chaîne obligatoire ne doit pas demander plusieurs timers longs strictement séquentiels. Si une progression nécessite 15 minutes réelles, le joueur doit pouvoir faire autre chose de significatif pendant ce temps.

Les longues durées de plusieurs heures ne font pas partie de la v0.3.

## Structure verticale

La mine possède un **axe vertical principal continu**. La caméra peut se déplacer du niveau de surface jusqu'à la profondeur maximale atteinte.

Les profondeurs sont découpées en :

- **pas de forage** : petites descentes régulières, initialement 10 m ;
- **grands paliers** : tous les 30 m dans le réglage initial ;
- **zones géologiques** : groupes de plusieurs paliers avec identité visuelle et mécanique propre.

Chaque grand palier garantit une nouveauté importante. Entre deux grands paliers, des découvertes secondaires peuvent apparaître.

Exemple de progression initiale à tester :

| Profondeur | Rôle principal |
| --- | --- |
| 0–30 m | industrie de base : fer, charbon, cuivre |
| 30 m | première nouveauté de ressource / recette |
| 60 m | première contrainte de forage ou amélioration requise |
| 90 m | accès à une ressource ou branche technologique avancée |
| 120 m | première découverte ancienne majeure |
| 150 m | nouveau biome souterrain clairement distinct |

Les contenus précis de ces paliers peuvent évoluer pendant l'équilibrage, mais la règle « un grand palier = une nouveauté visible ou mécanique » est obligatoire.

## Poches latérales

Les poches apparaissent à gauche ou à droite du puits principal. Elles ne bloquent jamais la descente normale.

Deux familles existent.

### Poches épuisables

Exemples : filon riche, cache, cavité instable, gisement concentré.

- coût d'accès en ressources ;
- timer d'exploration ou d'exploitation ;
- gain ponctuel ou limité ;
- la poche reste visible dans l'historique de la mine après épuisement, mais n'occupe plus de capacité active.

### Sites permanents

Exemples : gisement profond, source géothermique, complexe ancien exploitable, cavité cristalline.

- coût d'ouverture ;
- timer d'exploration ;
- devient ensuite une installation persistante ;
- peut être activé ou désactivé selon la capacité disponible ;
- reste visible dans la mine pour matérialiser l'histoire de la partie.

## Détection et information partielle

Une poche importante n'annonce pas immédiatement sa récompense exacte. Elle expose un **indice** correspondant à sa famille :

- `Forte signature minérale` ;
- `Structure inconnue` ;
- `Anomalie détectée` ;
- `Cavité instable`.

Le joueur doit pouvoir estimer la nature générale de l'opportunité sans connaître exactement son contenu.

Le résultat réel est déterminé de façon persistante au moment de la génération de la poche. Sauvegarder et recharger ne doit jamais permettre de relancer le tirage.

## Récompenses semi-aléatoires

Le type de poche garantit une **catégorie** de récompense ; la valeur exacte varie dans une plage définie.

Exemples :

- signature minérale → ressource garantie, quantité variable ;
- structure inconnue → récompense technologique garantie, forme précise variable ;
- cavité instable → bonus temporaire garanti, intensité ou durée variable.

La branche **Exploration** améliore progressivement la qualité minimale des récompenses. Elle ne supprime pas totalement l'aléatoire.

Toute génération aléatoire persistante doit utiliser une graine enregistrée ou stocker directement le résultat généré.

## Événements temporaires

Deux sources d'événements temporaires sont prévues :

1. événements déclenchés par un forage ou une nouvelle profondeur ;
2. événements pouvant apparaître pendant que l'exploitation fonctionne.

Un événement temporaire doit demander un **petit choix stratégique**, pas un simple bouton de collecte.

Exemple : un filon instable peut être affecté pendant quelques minutes à l'une de plusieurs ressources, avec un bénéfice différent selon le choix.

Les événements :

- ne doivent jamais bloquer la partie ;
- ne doivent pas punir le joueur s'il ne les voit pas ;
- peuvent expirer ;
- doivent avoir un état sauvegardé avec heure de début et de fin ;
- doivent rester rares assez pour être remarquables.

La fréquence exacte n'est pas figée dans la spec et devra être calibrée en jeu.

## Capacité d'exploitation

Digger utilise une seule ressource abstraite : **Capacité d'exploitation**.

Elle représente globalement l'énergie, les équipes et la logistique sans les simuler séparément.

Réglage initial :

- départ : **3 points de capacité** ;
- un petit site permanent coûte généralement 1 point ;
- un site avancé coûte généralement 2 points ;
- les sites exceptionnels peuvent coûter 3 points.

Tous les sites permanents restent construits, mais seuls les sites actifs consomment de la capacité et produisent leurs effets.

Le joueur peut désactiver un site et réaffecter sa capacité. Une désactivation ne détruit aucune progression du site.

## Centre d'exploitation

La surface possède un **Centre d'exploitation** évolutif.

La profondeur débloque le droit d'augmenter la capacité, mais l'amélioration doit ensuite être achetée avec les ressources industrielles de la partie.

Le modèle est donc :

`profondeur atteinte → nouveau plafond débloqué → amélioration du Centre → capacité réellement disponible`

Les premiers niveaux sont linéaires et faciles à comprendre. Ils servent principalement à augmenter la capacité globale.

À partir d'un palier de progression intermédiaire, initialement autour de 90–120 m, le Centre débloque trois spécialisations.

## Spécialisations

Trois branches sont prévues.

### Production

Améliore l'économie principale :

- débit d'extraction ;
- durée de fabrication ;
- efficacité de certaines installations.

### Logistique

Améliore l'exploitation simultanée :

- capacité globale ;
- coût en capacité de certains sites ;
- flexibilité d'activation des sites.

### Exploration

Améliore la progression et les découvertes :

- durée de certaines explorations ;
- qualité minimale des récompenses semi-aléatoires ;
- qualité ou fréquence contrôlée de certaines découvertes rares.

Les trois branches sont **cumulables**. Aucune décision ne ferme définitivement les autres branches.

Le joueur choisit cependant une **branche prioritaire**. Cette priorité procure un avantage de progression, par exemple coût inférieur ou progression technologique accélérée. La valeur exacte doit rester data-driven afin de pouvoir être équilibrée.

La priorité peut être changée ; la v0.3 ne doit pas imposer de respec punitif.

## Points technologiques

Une amélioration technologique nécessite deux conditions :

1. un **Point technologique** pour débloquer le savoir ;
2. des ressources industrielles pour construire/appliquer l'amélioration.

Les points technologiques viennent de deux sources :

- certains grands paliers de profondeur : récompenses garanties suffisantes pour suivre la progression normale ;
- certaines poches latérales importantes : points supplémentaires récompensant l'exploration.

Le joueur qui ignore toutes les poches latérales doit pouvoir terminer la progression principale. L'exploration donne plus de flexibilité et permet d'accélérer ou diversifier les spécialisations.

## Ressources et contenu

La v0.3 conserve le noyau `iron`, `coal`, `copper`, `iron_ingot`, `copper_ingot`, `cable` de la v0.2.

De nouvelles ressources peuvent être introduites à certains grands paliers, mais leur nombre doit rester faible dans une première implémentation. La priorité est de prouver la progression et les systèmes, pas de remplir artificiellement un catalogue.

Une nouvelle ressource doit obligatoirement avoir au moins un usage clair : recette, amélioration, exploration ou technologie.

## Carte et caméra

La vue principale est une **coupe verticale continue** de la mine.

Interactions :

- glisser verticalement pour parcourir les profondeurs ;
- inertie légère ;
- zoom limité ;
- bouton ou raccourci vers le chantier actif ;
- raccourcis vers les grands paliers lorsque la mine devient profonde.

La caméra ne devient pas une caméra libre 2D complète. Le mouvement horizontal est limité à ce qui est nécessaire pour cadrer les poches latérales.

Un événement important peut proposer un recentrage, mais ne doit pas arracher automatiquement la caméra pendant une interaction utilisateur.

## Interaction dans le monde

Les actions courantes se font directement sur la mine :

- toucher/clicker une mine → production et amélioration ;
- toucher une poche → exploration ou exploitation ;
- toucher la foreuse → état du chantier et lancement ;
- toucher un site permanent → activer, désactiver, améliorer ;
- toucher un événement → choix associé.

Les systèmes plus complexes restent accessibles par les écrans dédiés `Industrie`, `Centre` et `Technologie`.

## HUD cible

La mine doit occuper la majorité de l'écran.

### Barre haute

Affichage compact des ressources et états principaux :

- Fer ;
- Cuivre ;
- Charbon ;
- Capacité utilisée / totale ;
- profondeur actuelle/maximale pertinente.

Les ressources avancées ne doivent pas toutes saturer la barre supérieure. Elles peuvent être regroupées dans les panneaux spécialisés.

### Navigation basse

Quatre onglets principaux :

- **Mine** ;
- **Industrie** ;
- **Centre** ;
- **Technologie**.

### Panneaux contextuels

Un clic dans le monde ouvre un panneau contextuel non bloquant montrant seulement les données utiles :

- nom ;
- niveau ;
- rendement ;
- capacité ;
- coût ;
- timer éventuel ;
- action principale.

Les timers doivent aussi être visibles sur les installations concernées dans la vue de mine via une barre ou un compteur compact.

## Vie visuelle de l'exploitation

La mine doit paraître active sans devenir illisible.

Animations prévues :

- ascenseur circulant ;
- convoyeurs ;
- minerai transporté ;
- foreuse active pendant un chantier ;
- vapeur, lampes, signaux et mouvements mécaniques ;
- quelques véhicules ou wagonnets ;
- petites équipes stylisées sur certains sites.

Les animations doivent, autant que possible, refléter un état logique réel : installation active, chantier en cours, site désactivé, événement disponible.

Les ouvriers ne sont pas des entités de gameplay individuelles.

## Base de surface évolutive

La surface reflète durablement la progression :

- Centre d'exploitation ;
- atelier ;
- fonderie ;
- stockage ;
- infrastructures secondaires.

L'évolution visuelle combine :

- **petits ajouts entre niveaux** : conduites, silos, antennes, passerelles, éclairage, extensions ;
- **transformations importantes à certains paliers** : nouvelle silhouette ou bâtiment notable.

La surface reste une représentation de la progression, pas une seconde carte de gestion.

## Direction artistique verrouillée

Direction finale : **industriel contemporain avec une touche sci-fi sobre**.

### Surface et couches supérieures

- acier, béton, métal peint ;
- bâtiments et machines crédibles ;
- grues, camions, convoyeurs, silos et conduites ;
- éclairage industriel chaud ;
- palette gris acier / roche sombre / ambre.

### Profondeurs

Plus le joueur descend, plus la direction visuelle devient mystérieuse :

- accents cyan et turquoise ;
- cristaux lumineux ;
- anomalies visuelles ;
- structures anciennes ou technologies inconnues ;
- contraste croissant avec l'industrie humaine de la surface.

La transition doit être progressive. Digger ne devient pas brutalement un univers spatial ou magique.

### HUD

- panneaux bleu nuit / gris très sombre ;
- typographie moderne, forte lisibilité ;
- accents ambre pour l'action principale ;
- cyan/turquoise réservé aux technologies, cristaux et anomalies ;
- pas de cadres steampunk lourds ;
- peu d'ornementation gratuite.

## Architecture logique proposée

La v0.3 doit prolonger la séparation déjà utilisée dans la v0.2 : modèle déterministe, session/horloge, sauvegarde, rendu.

Composants logiques à introduire ou étendre :

### `IndustryCatalog`

Devient le catalogue data-driven des :

- ressources ;
- recettes ;
- mines ;
- paliers de profondeur ;
- types de poches ;
- technologies ;
- spécialisations ;
- coûts de capacité.

Les valeurs d'équilibrage ne doivent pas être dispersées dans l'UI.

### `IndustryGame`

Reste propriétaire de l'état économique déterministe et ajoute :

- capacité totale et utilisée ;
- niveau du Centre ;
- profondeur/paliers débloqués ;
- sites permanents ;
- poches découvertes ;
- explorations en cours ;
- événements actifs ;
- points technologiques ;
- technologies débloquées/construites ;
- branche prioritaire.

### Génération de découvertes

Un composant logique dédié peut générer les poches depuis :

- profondeur ;
- identifiant/palier ;
- seed persistante de partie.

Il doit produire des résultats reproductibles et sérialisables.

### `IndustrySession`

Continue de gérer le temps réel et hors ligne. Elle doit faire avancer :

- production ;
- lots ;
- forage ;
- exploration ;
- événements temporaires.

Un grand saut de temps doit donner le même état logique que plusieurs petits sauts équivalents.

### Vue mine

La vue doit être séparée du modèle. Elle transforme l'état en :

- profondeur ;
- couches géologiques ;
- bâtiments ;
- sites ;
- animations d'état ;
- panneaux interactifs.

Aucune ressource ne doit être créée directement par une animation ou un callback graphique.

## Sauvegarde et migration

La v0.3 doit charger une sauvegarde industrielle v0.2 existante sans perte de progression.

Le schéma de sauvegarde doit être versionné. À la première ouverture v0.3 :

- ressources, niveaux de mines, niveau de foreuse, profondeur et travaux v0.2 sont conservés ;
- les nouveaux systèmes sont initialisés à leurs valeurs par défaut cohérentes avec la profondeur existante ;
- aucune découverte v0.3 ne doit être dupliquée lors des réouvertures suivantes.

Les règles de sauvegarde atomique de la v0.2 restent obligatoires.

Une sauvegarde invalide reste préservée et la session provisoire ne l'écrase pas.

## Gestion des erreurs

Le modèle doit refuser sans mutation partielle :

- coût insuffisant ;
- capacité insuffisante ;
- site inconnu ;
- poche déjà exploitée ;
- technologie non débloquée ;
- point technologique manquant ;
- profondeur insuffisante ;
- données de découverte incohérentes ;
- état de timer invalide.

L'UI traduit le motif de refus en message court et actionnable.

## Tests obligatoires

### Modèle

- activation/désactivation de sites et calcul de capacité ;
- refus atomique si capacité insuffisante ;
- progression du Centre et verrou par profondeur ;
- obtention de points technologiques ;
- déblocage puis construction d'une technologie ;
- branche prioritaire sans verrou des autres branches ;
- génération reproductible des poches ;
- résultat d'une poche inchangé après sauvegarde/rechargement ;
- poche épuisable ;
- site permanent ;
- qualité minimale modifiée par Exploration ;
- événement temporaire, expiration et choix ;
- avancement par gros saut = avancement fractionné.

### Persistance

- migration d'une sauvegarde v0.2 ;
- sauvegarde/reprise d'une exploration active ;
- sauvegarde/reprise d'un événement temporaire ;
- absence hors ligne terminant plusieurs types de travaux ;
- absence sans double attribution ;
- seed et découvertes persistantes ;
- sauvegarde invalide préservée.

### UI

- défilement vertical ;
- zoom limité ;
- clic sur mine, poche, foreuse et site permanent ;
- activation/désactivation de site ;
- panneaux contextuels ;
- navigation Mine / Industrie / Centre / Technologie ;
- écran étroit sans perte d'action essentielle ;
- rendu d'au moins trois zones géologiques visuellement distinctes ;
- capture graphique CI large et étroite.

Les tests v0.1 et v0.2 existants restent verts.

## Critères d'acceptation v0.3

La v0.3 est considérée comme réussie si un nouveau joueur peut, sans outil de debug :

1. démarrer avec l'industrie v0.2 ;
2. descendre sur plusieurs paliers ;
3. voir au moins une découverte latérale ;
4. choisir de l'explorer avec ressources + temps ;
5. transformer au moins une découverte en bénéfice permanent ou ponctuel ;
6. atteindre un palier qui débloque une amélioration du Centre ;
7. augmenter sa capacité et activer un site supplémentaire ;
8. obtenir un point technologique ;
9. débloquer puis construire une amélioration de spécialisation ;
10. quitter puis revenir sans perdre ni dupliquer production, travaux, événements ou découvertes ;
11. comprendre son exploitation principalement depuis la vue verticale de la mine.

Le parcours doit contenir plusieurs décisions utiles en moins de dix minutes lors du début de partie. Les timers plus longs doivent apparaître progressivement et laisser d'autres actions disponibles.

## Hors périmètre v0.3

- gestion individuelle des ouvriers ;
- énergie détaillée ;
- réseau logistique simulé physiquement ;
- combat ;
- PNJ narratifs complexes ;
- marché multijoueur ;
- compte en ligne ;
- notifications push ;
- monétisation ;
- timers obligatoires de plusieurs heures ;
- arbre technologique massif ;
- dizaines de nouvelles ressources ;
- génération procédurale infinie de contenu unique.

## Décision de production

La v0.3 doit être construite par tranches jouables. La priorité est :

1. structure de profondeur et découvertes ;
2. sites permanents + capacité + Centre ;
3. technologie et spécialisations ;
4. événements temporaires ;
5. vue verticale/HUD final et enrichissement visuel.

Le graphisme final doit viser la composition validée : mine verticale dominante, surface industrielle crédible, interface sombre et propre, mystère visuel croissant dans les profondeurs. La première implémentation doit privilégier des assets modulaires réutilisables plutôt que tenter immédiatement le niveau de détail d'une illustration conceptuelle unique.
