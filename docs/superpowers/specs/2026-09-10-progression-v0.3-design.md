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
7. révéler un contenu : contrainte, site, technologie ou événement ;
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

- **pas de forage** : petites descentes régulières de 10 m ;
- **grands paliers** : tous les 30 m pour la v0.3 ;
- **zones géologiques** : groupes de plusieurs paliers avec identité visuelle et mécanique propre.

Chaque grand palier garantit une nouveauté importante. Entre deux grands paliers, des découvertes secondaires peuvent apparaître.

### Contenu minimal de progression v0.3

| Profondeur | Déblocage garanti |
| --- | --- |
| 0–20 m | industrie v0.2 et tutoriel de la vue verticale |
| 30 m | première poche latérale épuisable + Centre niveau 2 disponible |
| 60 m | strate de roche dense + Centre niveau 3 disponible ; foreuse niveau 2 requise pour dépasser ce palier |
| 90 m | spécialisations + 1 Point technologique garanti + Centre niveau 4 disponible + première cavité cristalline possible |
| 120 m | structure ancienne majeure + 1 Point technologique garanti + Centre niveau 5 disponible |
| 150 m | nouveau biome profond + 1 Point technologique garanti + Centre niveau 6 disponible |

Le contenu au-delà de 150 m n'est pas requis pour valider la v0.3. La profondeur peut rester techniquement extensible.

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

## Ressource profonde minimale

La v0.3 ajoute une seule ressource profonde obligatoire au catalogue : `crystal` / **Cristal brut**.

Elle apparaît à partir de 90 m dans les cavités cristallines permanentes. Une cavité cristalline coûte 2 points de capacité lorsqu'elle est active et produit lentement du cristal brut.

Le cristal brut sert aux coûts de construction des améliorations technologiques de rang supérieur et prépare les versions futures. La progression principale jusqu'à 150 m ne doit cependant jamais dépendre d'un tirage aléatoire de cavité : le premier accès à une cavité cristalline doit être garanti par la seed de progression ou par un site de palier dédié.

Aucune autre nouvelle ressource n'est requise pour la v0.3.

## Événements temporaires

Deux sources d'événements temporaires sont prévues :

1. événements déclenchés par un forage ou une nouvelle profondeur ;
2. événements pouvant apparaître pendant une session active lorsque l'exploitation fonctionne.

Un événement temporaire doit demander un **petit choix stratégique**, pas un simple bouton de collecte.

Premier événement obligatoire : **Filon instable**. Il propose d'affecter le bonus au fer, au cuivre ou au charbon. Le choix augmente fortement le débit de la ressource choisie pendant quelques minutes. Les valeurs exactes restent data-driven.

Règles :

- un événement ne bloque jamais la partie ;
- un événement non vu ne doit jamais pénaliser le joueur ;
- les événements ambiants aléatoires ne sont générés que pendant une session active ;
- un événement produit par un travail terminé hors ligne est mis en attente et son timer commence uniquement lorsqu'il est présenté au joueur ;
- un événement déjà présenté peut expirer normalement ;
- début, fin, choix et état de présentation sont sauvegardés.

La fréquence exacte doit être calibrée en jeu et n'est pas un critère de progression.

## Capacité d'exploitation

Digger utilise une seule ressource abstraite : **Capacité d'exploitation**.

Elle représente globalement l'énergie, les équipes et la logistique sans les simuler séparément.

Tous les sites permanents restent construits, mais seuls les sites actifs consomment de la capacité et produisent leurs effets. Le joueur peut désactiver un site et réaffecter sa capacité. Une désactivation ne détruit aucune progression du site.

### Paliers du Centre

| Centre | Profondeur requise | Capacité de base |
| --- | ---: | ---: |
| Niveau 1 | 0 m | 3 |
| Niveau 2 | 30 m | 4 |
| Niveau 3 | 60 m | 5 |
| Niveau 4 | 90 m | 6 |
| Niveau 5 | 120 m | 7 |
| Niveau 6 | 150 m | 8 |

Le coût exact d'amélioration du Centre reste dans le catalogue et doit augmenter avec le niveau en utilisant les ressources industrielles déjà disponibles.

Un petit site permanent coûte généralement 1 point, un site avancé 2 points et un site exceptionnel 3 points.

## Centre d'exploitation

La surface possède un **Centre d'exploitation** évolutif.

La profondeur débloque le droit d'augmenter la capacité, mais l'amélioration doit ensuite être achetée avec les ressources industrielles de la partie.

Le modèle est donc :

`profondeur atteinte → niveau de Centre autorisé → achat de l'amélioration → capacité réellement disponible`

Les premiers niveaux sont linéaires. Au niveau 4 / 90 m, le Centre donne accès aux spécialisations.

## Spécialisations

Trois branches sont prévues et restent **cumulables**.

### Production

Premier effet v0.3 : **Production I** augmente de 10 % les débits d'extraction bruts.

### Logistique

Premier effet v0.3 : **Logistique I** ajoute 1 point permanent de capacité d'exploitation au-delà de la capacité fournie par le Centre.

### Exploration

Premier effet v0.3 : **Exploration I** relève de 20 % le plancher de qualité utilisé lors du calcul des récompenses variables d'une poche. Une récompense garde donc sa plage et sa part de hasard, mais les résultats les plus faibles deviennent impossibles.

Ces trois technologies constituent le minimum obligatoire de la v0.3. L'architecture doit permettre d'ajouter des rangs suivants sans modifier les sauvegardes existantes.

## Branche prioritaire

Le joueur choisit une branche prioritaire parmi Production, Logistique et Exploration.

La priorité donne un bonus passif distinct des technologies achetées :

- priorité Production : +10 % supplémentaires aux débits bruts ;
- priorité Logistique : +1 point de capacité tant que cette priorité est active ;
- priorité Exploration : +20 % supplémentaires au plancher de qualité des récompenses variables.

Changer de priorité ne rembourse ni ne retire aucune technologie. Le changement est gratuit mais déclenche un délai de **5 minutes** avant qu'un nouveau changement soit autorisé. Le cooldown est sauvegardé et continue hors ligne.

Cette règle évite de changer de priorité avant chaque clic tout en permettant de réorienter une partie sans respec punitif.

## Points technologiques

Une amélioration technologique nécessite deux conditions :

1. **1 Point technologique** pour débloquer le savoir ;
2. des ressources industrielles pour construire/appliquer l'amélioration.

Les points technologiques viennent de deux sources :

- grands paliers de profondeur : 1 point garanti à 90 m, 120 m et 150 m ;
- certaines poches latérales importantes : points supplémentaires récompensant l'exploration.

Les points de palier suffisent pour construire au moins une amélioration dans chacune des trois branches. Le joueur qui ignore toutes les poches latérales doit pouvoir suivre la progression principale. L'exploration donne plus de flexibilité et prépare les rangs futurs.

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
- profondeur.

Les ressources avancées ne doivent pas toutes saturer la barre supérieure. Le cristal brut apparaît dans Industrie/Technologie et dans les panneaux concernés.

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

La v0.3 prolonge la séparation de la v0.2 : modèle déterministe, session/horloge, sauvegarde, rendu.

### `IndustryCatalog`

Devient le catalogue data-driven des :

- ressources ;
- recettes ;
- mines ;
- paliers de profondeur ;
- types de poches ;
- technologies ;
- spécialisations ;
- coûts de capacité ;
- événements et bonus.

Les valeurs d'équilibrage ne doivent pas être dispersées dans l'UI.

### `IndustryGame`

Reste propriétaire de l'état économique déterministe et ajoute :

- capacité totale et utilisée ;
- niveau du Centre ;
- paliers débloqués et récompenses de palier réclamées ;
- sites permanents ;
- poches découvertes ;
- explorations en cours ;
- événements actifs/en attente ;
- points technologiques ;
- technologies débloquées/construites ;
- branche prioritaire et cooldown de changement ;
- seed persistante de partie.

### `IndustryDiscovery`

Composant logique sans UI chargé de générer une découverte depuis :

- seed de partie ;
- profondeur ;
- emplacement/slot de découverte ;
- type de zone.

Le même triplet logique doit toujours produire le même résultat. Une fois une poche créée, son résultat complet est sérialisé et devient la source de vérité.

### `IndustrySession`

Continue de gérer le temps réel et hors ligne. Elle fait avancer :

- production ;
- lots ;
- forage ;
- exploration ;
- événements déjà présentés ;
- cooldown de priorité.

Un grand saut de temps doit donner le même état logique que plusieurs petits sauts équivalents.

### Vue mine

La vue transforme l'état en :

- profondeur ;
- couches géologiques ;
- bâtiments ;
- sites ;
- animations d'état ;
- panneaux interactifs.

Aucune ressource ne doit être créée directement par une animation ou un callback graphique.

## Sauvegarde et migration

La sauvegarde industrielle passe à un schéma v2 tout en conservant le même fichier logique `user://industry_v1.json` pour éviter deux progressions concurrentes.

La v0.3 doit charger une sauvegarde v0.2/schema v1 existante sans perte de progression.

À la première migration :

- ressources, niveaux de mines, niveau de foreuse, profondeur et travaux v0.2 sont conservés ;
- `center_level` démarre à 1 ;
- le niveau maximal du Centre immédiatement achetable est calculé depuis la profondeur déjà atteinte ;
- les améliorations de Centre ne sont pas offertes automatiquement ;
- les Points technologiques garantis correspondant aux seuils déjà dépassés sont crédités une seule fois et les récompenses de palier sont marquées comme réclamées ;
- la seed de partie est créée une seule fois puis sauvegardée ;
- les poches correspondant aux profondeurs déjà explorées sont générées une seule fois depuis cette seed ;
- aucune technologie ni priorité n'est choisie automatiquement.

Les règles de sauvegarde atomique de la v0.2 restent obligatoires. Une sauvegarde invalide reste préservée et la session provisoire ne l'écrase pas.

## Gestion des erreurs

Le modèle doit refuser sans mutation partielle :

- coût insuffisant ;
- capacité insuffisante ;
- site inconnu ;
- poche déjà exploitée ;
- technologie non débloquée ;
- Point technologique manquant ;
- profondeur insuffisante ;
- niveau de Centre non autorisé ;
- données de découverte incohérentes ;
- état de timer invalide ;
- changement de priorité pendant le cooldown.

L'UI traduit le motif de refus en message court et actionnable.

## Tests obligatoires

### Modèle

- activation/désactivation de sites et calcul de capacité ;
- refus atomique si capacité insuffisante ;
- progression du Centre et verrou par profondeur ;
- obtention de Points technologiques ;
- déblocage puis construction d'une technologie ;
- trois technologies initiales et trois bonus de priorité ;
- cooldown de priorité ;
- génération reproductible des poches ;
- résultat d'une poche inchangé après sauvegarde/rechargement ;
- poche épuisable ;
- site permanent ;
- production de cristal ;
- qualité minimale modifiée par Exploration ;
- événement Filon instable, choix et expiration ;
- événement issu d'un travail hors ligne mis en attente sans expiration invisible ;
- avancement par gros saut = avancement fractionné.

### Persistance

- migration d'une sauvegarde v0.2/schema v1 ;
- attribution rétroactive unique des Points technologiques de palier ;
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
6. atteindre 90 m et débloquer le système technologique ;
7. améliorer le Centre et augmenter sa capacité ;
8. activer/désactiver des sites selon cette capacité ;
9. obtenir un Point technologique ;
10. choisir une branche prioritaire puis construire une technologie ;
11. rencontrer ou déclencher le premier événement stratégique ;
12. quitter puis revenir sans perdre ni dupliquer production, travaux, événements ou découvertes ;
13. comprendre son exploitation principalement depuis la vue verticale de la mine.

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
- plus d'une nouvelle ressource profonde obligatoire ;
- génération procédurale infinie de contenu unique.

## Ordre de production

La v0.3 doit être construite par tranches jouables :

1. **profondeur + paliers + génération persistante des découvertes** ;
2. **poches + sites permanents + capacité + Centre** ;
3. **Points technologiques + spécialisations + priorité** ;
4. **événement Filon instable + règles offline** ;
5. **vue verticale interactive + HUD final** ;
6. **animations et enrichissement visuel modulaire**.

Le graphisme final vise la composition validée : mine verticale dominante, surface industrielle crédible, interface sombre et propre, mystère visuel croissant dans les profondeurs. La première implémentation doit privilégier des assets modulaires réutilisables plutôt que tenter immédiatement le niveau de détail d'une illustration conceptuelle unique.
