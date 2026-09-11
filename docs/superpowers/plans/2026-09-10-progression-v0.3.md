# Project Digger — Progression v0.3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformer la boucle industrielle v0.2 en progression verticale durable jusqu’à 150 m, avec découvertes persistantes, capacité d’exploitation, Centre, technologies, événement stratégique et nouvelle vue mine interactive.

**Architecture:** Conserver la séparation v0.2 entre modèle déterministe, session/horloge, sauvegarde et rendu. Étendre `IndustryGame` comme source de vérité, introduire `IndustryDiscovery` pour la génération reproductible, migrer la sauvegarde au schéma v2, puis remplacer progressivement l’écran de gestion actuel par une vue verticale interactive et des panneaux spécialisés sans faire dépendre le gameplay du rendu.

**Tech Stack:** Godot 4.7.2 stable, GDScript, renderer `gl_compatibility`, tests maison via `tests/test_runner.gd`, tests UI réels via `tests/test_industry_ui.gd`, GitHub Actions existante.

**Spec:** `docs/superpowers/specs/2026-09-10-progression-v0.3-design.md`

## Global Constraints

- Base de travail : `feature/progression-v0.3`, issue de `feature/industry-v0.2`.
- Godot 4.7.2 stable, GDScript, rendu `gl_compatibility`, aucun plugin tiers.
- Conserver la progression v0.2 existante : fer, charbon, cuivre, lingots, câble, mines, foreuse, lots, production hors ligne.
- Sauvegarde logique unique : `user://industry_v1.json`, schéma interne v2 après migration.
- Sauvegarde atomique obligatoire ; un fichier invalide reste préservé et n’est jamais écrasé par une session provisoire.
- Pas de gestion individuelle des ouvriers, pas d’énergie détaillée, pas de simulation physique de logistique, pas de combat, pas de compte en ligne, pas de monétisation.
- Timers v0.3 : 20–60 s au début, 1–3 min pour les premières transformations, 3–10 min au milieu, 10–20 min maximum pour les opérations tardives de cette version.
- Progression principale par pas de 10 m ; grands paliers à 30, 60, 90, 120 et 150 m.
- Le joueur qui ignore les poches latérales doit pouvoir suivre la progression principale jusqu’à 150 m.
- La vue mine devient l’écran principal ; `Industrie`, `Centre`, `Technologie` restent des écrans/panneaux dédiés.
- Direction graphique : industriel contemporain en surface et couches hautes, touche sci-fi sobre croissante en profondeur, HUD sombre bleu nuit, action principale ambre, cyan/turquoise réservé aux technologies/cristaux/anomalies.
- Toute valeur d’équilibrage ajoutée par ce plan vit dans `IndustryCatalog`, jamais dans l’UI.
- Tous les tests v0.1 et v0.2 restent verts à la fin de chaque tâche.

---

## File map cible

### Modèle et données

- `src/industry/industry_catalog.gd` — catalogue des ressources, recettes, mines, Centre, paliers, poches, technologies, événements et coûts.
- `src/industry/industry_game.gd` — état déterministe complet et règles économiques.
- `src/industry/industry_discovery.gd` — génération reproductible des découvertes à partir de la seed et de la profondeur.
- `src/industry/industry_save.gd` — schéma v2, migration du schéma v1 et sauvegarde atomique.
- `src/industry/industry_session.gd` — horloge réelle, hors ligne, événements différés, persistance et façade d’actions.

### UI

- `src/industry/ui/industry_screen.gd` — shell de navigation et orchestration UI.
- `src/industry/ui/mine_world.gd` — vue verticale continue, caméra, couches, sites et hit targets.
- `src/industry/ui/site_panel.gd` — panneau contextuel d’un site/poche/foreuse.
- `src/industry/ui/center_panel.gd` — Centre, capacité et activation des sites.
- `src/industry/ui/technology_panel.gd` — points technologiques, branches, priorité et cooldown.
- `src/industry/ui/industry_panel.gd` — extraction/fonderie/atelier, réemploi des widgets v0.2.
- `src/industry/ui/industry_theme.gd` — palette et helpers visuels.
- `src/industry/ui/mine_overview.gd` — conservé temporairement puis retiré de l’écran principal une fois `mine_world.gd` validé.

### Tests

- `tests/test_industry_discovery.gd`
- `tests/test_industry_game.gd`
- `tests/test_industry_save.gd`
- `tests/test_industry_session.gd`
- `tests/test_progression_acceptance.gd`
- `tests/test_industry_ui.gd`
- `tests/test_runner.gd`

---

### Task 1: Catalogue v0.3 + générateur reproductible de découvertes

**Files:**
- Modify: `src/industry/industry_catalog.gd`
- Create: `src/industry/industry_discovery.gd`
- Create: `tests/test_industry_discovery.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Consumes: aucune nouvelle interface.
- Produces: `IndustryDiscovery.generate(seed: int, depth: int, slot: int, quality_floor: float) -> Dictionary`.
- Produces catalogue : `CENTER_LEVELS`, `MILESTONES`, `POCKET_TYPES`, `TECHNOLOGIES`, `PRIORITY_BONUSES`, `EVENTS`.

- [ ] **Step 1: Ajouter le test de génération déterministe**

Créer `tests/test_industry_discovery.gd` :

```gdscript
extends RefCounted

const Discovery = preload("res://src/industry/industry_discovery.gd")

func run(t) -> void:
    var a := Discovery.generate(123456, 30, 0, 0.0)
    var b := Discovery.generate(123456, 30, 0, 0.0)
    t.check(a == b, "même seed/profondeur/slot = même découverte")
    t.check(a.has("id") and a.has("kind") and a.has("hint") and a.has("reward"), "découverte sérialisable complète")

    var low := Discovery.generate(123456, 90, 1, 0.0)
    var boosted := Discovery.generate(123456, 90, 1, 0.4)
    t.check(float(boosted["quality"]) >= float(low["quality"]), "le plancher Exploration ne baisse jamais la qualité")
    t.check(float(boosted["quality"]) >= 0.4, "plancher de qualité respecté")
```

Ajouter à `TEST_SUITES` :

```gdscript
preload("res://tests/test_industry_discovery.gd"),
```

- [ ] **Step 2: Exécuter et constater l’échec**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: échec de preload car `src/industry/industry_discovery.gd` n’existe pas.

- [ ] **Step 3: Étendre le catalogue avec les valeurs initiales**

Dans `industry_catalog.gd`, ajouter la ressource et les tables suivantes :

```gdscript
# Ajouter dans RESOURCES
"crystal": {"label": "Cristal brut", "raw": true},

const CENTER_LEVELS := {
    1: {"depth": 0, "capacity": 3, "cost": {}},
    2: {"depth": 30, "capacity": 4, "cost": {"iron": 24, "coal": 10}},
    3: {"depth": 60, "capacity": 5, "cost": {"iron_ingot": 4, "cable": 1}},
    4: {"depth": 90, "capacity": 6, "cost": {"iron_ingot": 6, "copper_ingot": 4, "cable": 2}},
    5: {"depth": 120, "capacity": 7, "cost": {"iron_ingot": 10, "copper_ingot": 8, "cable": 4, "crystal": 6}},
    6: {"depth": 150, "capacity": 8, "cost": {"iron_ingot": 16, "copper_ingot": 12, "cable": 6, "crystal": 12}},
}

const MILESTONES := {
    30: {"center_level": 2, "tech_points": 0, "guaranteed_pocket": "rich_vein"},
    60: {"center_level": 3, "tech_points": 0, "requires_drill": 2},
    90: {"center_level": 4, "tech_points": 1, "guaranteed_pocket": "crystal_cavern"},
    120: {"center_level": 5, "tech_points": 1, "guaranteed_pocket": "ancient_structure"},
    150: {"center_level": 6, "tech_points": 1, "biome": "deep_zone"},
}

const POCKET_TYPES := {
    "rich_vein": {"kind": "exhaustible", "hint": "Forte signature minérale", "capacity": 0},
    "unstable_cavity": {"kind": "exhaustible", "hint": "Cavité instable", "capacity": 0},
    "crystal_cavern": {"kind": "permanent", "hint": "Anomalie minérale", "capacity": 2},
    "ancient_structure": {"kind": "permanent", "hint": "Structure inconnue", "capacity": 2},
}

const TECHNOLOGIES := {
    "production_1": {"branch": "production", "tech_points": 1, "cost": {"iron_ingot": 6, "cable": 2}, "effect": 0.10},
    "logistics_1": {"branch": "logistics", "tech_points": 1, "cost": {"iron_ingot": 5, "copper_ingot": 4, "cable": 2}, "effect": 1},
    "exploration_1": {"branch": "exploration", "tech_points": 1, "cost": {"copper_ingot": 5, "cable": 3, "crystal": 4}, "effect": 0.20},
}

const PRIORITY_BONUSES := {
    "production": {"production_rate": 0.10},
    "logistics": {"capacity": 1},
    "exploration": {"quality_floor": 0.20},
}

const EVENTS := {
    "unstable_vein": {"duration": 300.0, "rate_bonus": 1.0, "choices": ["iron", "copper", "coal"]},
}
```

- [ ] **Step 4: Implémenter `IndustryDiscovery` sans état global**

Créer `src/industry/industry_discovery.gd` :

```gdscript
class_name IndustryDiscovery
extends RefCounted

const Catalog = preload("res://src/industry/industry_catalog.gd")

static func generate(seed: int, depth: int, slot: int, quality_floor: float) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([seed, depth, slot])
    var forced := ""
    if Catalog.MILESTONES.has(depth):
        forced = str(Catalog.MILESTONES[depth].get("guaranteed_pocket", ""))
    var type_id := forced
    if type_id == "":
        var candidates := ["rich_vein", "unstable_cavity"]
        if depth >= 90:
            candidates.append("crystal_cavern")
        type_id = candidates[rng.randi_range(0, candidates.size() - 1)]
    var quality := maxf(clampf(quality_floor, 0.0, 0.8), rng.randf())
    var definition: Dictionary = Catalog.POCKET_TYPES[type_id]
    var reward := _reward_for(type_id, quality)
    return {
        "id": "%d:%d" % [depth, slot],
        "depth": depth,
        "slot": slot,
        "type": type_id,
        "kind": definition["kind"],
        "hint": definition["hint"],
        "quality": quality,
        "reward": reward,
        "state": "detected",
        "active": false,
    }

static func _reward_for(type_id: String, quality: float) -> Dictionary:
    match type_id:
        "rich_vein":
            return {"resource": "iron", "amount": 40 + int(round(quality * 40.0))}
        "unstable_cavity":
            return {"event": "unstable_vein"}
        "crystal_cavern":
            return {"resource": "crystal", "rate": 0.025 + quality * 0.015}
        "ancient_structure":
            return {"tech_points": 1}
    return {}
```

- [ ] **Step 5: Vérifier la suite et committer**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: PASS, y compris v0.1/v0.2.

Commit:

```bash
git add src/industry/industry_catalog.gd src/industry/industry_discovery.gd tests/test_industry_discovery.gd tests/test_runner.gd
git commit -m "feat: add v0.3 progression catalog and discoveries"
```

---

### Task 2: Schéma d’état v0.3 + migration de sauvegarde v1 → v2

**Files:**
- Modify: `src/industry/industry_game.gd`
- Modify: `src/industry/industry_save.gd`
- Modify: `tests/test_industry_game.gd`
- Modify: `tests/test_industry_save.gd`

**Interfaces:**
- Produces `IndustryGame.restore_v1(data: Dictionary, seed: int) -> bool`.
- `snapshot()` inclut tous les nouveaux champs v0.3.
- `IndustrySave.SAVE_VERSION == 2`.

- [ ] **Step 1: Écrire les tests de nouvel état et migration**

Ajouter aux suites existantes :

```gdscript
var game = IndustryGame.new()
t.check(game.center_level == 1, "Centre niveau 1 par défaut")
t.check(game.tech_points == 0, "aucun point techno au départ")
t.check(game.discoveries.is_empty(), "aucune découverte au départ")
t.check(game.world_seed != 0, "seed de partie initialisée")

var snapshot := game.snapshot()
var restored = IndustryGame.new()
t.check(restored.restore(snapshot), "snapshot v0.3 restaurable")
t.check(restored.world_seed == game.world_seed, "seed persistée")
```

Dans `test_industry_save.gd`, écrire un payload v1 réel avec les clés v0.2 puis :

```gdscript
var loaded := save.load_game(path, 1000.0)
t.check(loaded["error"] == "", "schema v1 migré")
t.check(loaded["game"].resources["iron"] == 42.0, "stock v1 conservé")
t.check(loaded["game"].center_level == 1, "Centre initialisé à la migration")
t.check(loaded["game"].world_seed != 0, "seed créée à la migration")
```

- [ ] **Step 2: Vérifier l’échec**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL sur les nouveaux champs et `SAVE_VERSION`.

- [ ] **Step 3: Ajouter les champs v0.3 à `IndustryGame`**

Ajouter :

```gdscript
var center_level := 1
var permanent_sites: Dictionary = {}
var discoveries: Dictionary = {}
var claimed_milestones: Array[int] = []
var tech_points := 0
var unlocked_technologies: Array[String] = []
var built_technologies: Array[String] = []
var priority_branch := ""
var priority_cooldown_remaining := 0.0
var active_event: Dictionary = {}
var pending_events: Array[Dictionary] = []
var world_seed: int = 1
```

À l’initialisation, remplacer `world_seed = 1` par une seed non nulle créée une fois ; pour les tests, autoriser l’assignation directe avant snapshot. Ajouter `crystal: 0.0` dans `resources`.

Étendre `snapshot()` avec exactement ces clés et étendre `_valid_snapshot()` pour les valider strictement. Les découvertes et sites doivent être des dictionnaires JSON-compatibles, les tableaux de technologies doivent contenir uniquement des ids du catalogue, les timers doivent être finis et >= 0.

- [ ] **Step 4: Implémenter la migration v1 dans `IndustrySave`**

Passer :

```gdscript
const SAVE_VERSION := 2
```

Dans `load_game`, accepter version 1 ou 2. Pour version 1 :

```gdscript
func _migrate_v1(payload: Dictionary, logical_now: float) -> Dictionary:
    var candidate = IndustryGameScript.new()
    var seed := int(abs(hash(JSON.stringify(payload))))
    if seed == 0:
        seed = 1
    if not candidate.restore_v1(payload["industry"], seed):
        return _new_result(logical_now, "État industriel v1 incohérent")
    candidate.apply_retroactive_milestones()
    var saved_at := float(payload["saved_at_unix"])
    var offline_seconds := maxf(0.0, logical_now - saved_at)
    var report := candidate.advance(offline_seconds)
    return {
        "game": candidate,
        "saved_at_unix": maxf(saved_at, logical_now),
        "offline_seconds": offline_seconds,
        "offline_report": report,
        "error": "",
    }
```

`restore_v1()` reprend les validations v0.2, ajoute `crystal = 0`, puis initialise les nouveaux champs sans inventer de technologie/priorité.

- [ ] **Step 5: Vérifier migration, non-régression et commit**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: PASS, incluant ancienne sauvegarde v1, nouvelle sauvegarde v2 et sauvegarde invalide préservée.

Commit:

```bash
git add src/industry/industry_game.gd src/industry/industry_save.gd tests/test_industry_game.gd tests/test_industry_save.gd
git commit -m "feat: migrate industry saves to progression schema v2"
```

---

### Task 3: Paliers de profondeur, récompenses garanties et découvertes persistantes

**Files:**
- Modify: `src/industry/industry_game.gd`
- Modify: `tests/test_industry_game.gd`
- Modify: `tests/test_industry_discovery.gd`

**Interfaces:**
- Produces `apply_retroactive_milestones() -> void`.
- Produces `discoveries_for_depth(depth: int) -> Array[Dictionary]`.
- Produces `quality_floor() -> float`.

- [ ] **Step 1: Tests des seuils 30/60/90/120/150 m**

Ajouter :

```gdscript
var game = IndustryGame.new()
game.depth = 80
game.drill_level = 4
game.jobs["drill"] = {"target_depth": 90, "remaining": 1.0, "duration": 1.0}
game.advance(1.0)
t.check(game.depth == 90, "palier 90 m atteint")
t.check(game.tech_points == 1, "point techno 90 m attribué")
t.check(90 in game.claimed_milestones, "palier 90 m marqué")
t.check(not game.discoveries.is_empty(), "découverte de palier générée")
var count := game.discoveries.size()
game.apply_retroactive_milestones()
t.check(game.discoveries.size() == count and game.tech_points == 1, "palier idempotent")
```

Ajouter aussi un test vérifiant qu’une seed identique produit la même découverte après snapshot/restore.

- [ ] **Step 2: Vérifier l’échec**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL sur l’attribution de palier.

- [ ] **Step 3: Centraliser le traitement de fin de forage**

Dans la branche `facility == "drill"` de `advance()`, après mise à jour de `depth`, appeler :

```gdscript
_apply_milestones_up_to(depth)
_generate_depth_discoveries(depth)
```

Implémenter :

```gdscript
func _apply_milestones_up_to(target_depth: int) -> void:
    for milestone_depth in Catalog.MILESTONES:
        var d := int(milestone_depth)
        if d > target_depth or d in claimed_milestones:
            continue
        var data: Dictionary = Catalog.MILESTONES[d]
        tech_points += int(data.get("tech_points", 0))
        claimed_milestones.append(d)
        if data.has("guaranteed_pocket"):
            _ensure_discovery(d, 0)

func apply_retroactive_milestones() -> void:
    _apply_milestones_up_to(depth)
    for d in range(30, depth + 1, 10):
        _generate_depth_discoveries(d)
```

`_ensure_discovery(depth, slot)` appelle `IndustryDiscovery.generate(world_seed, depth, slot, quality_floor())` uniquement si l’id `"depth:slot"` n’existe pas déjà.

- [ ] **Step 4: Ajouter le verrou foreuse de 60 m**

Faire dépendre `excavation_block_reason()` des données de `MILESTONES` : pour une cible > 60 m, foreuse niveau 2 minimum ; conserver ensuite la progression existante par niveaux, sans créer un verrou plus faible que la v0.2.

- [ ] **Step 5: Vérifier et committer**

Run suite complète ; Expected: PASS.

Commit:

```bash
git add src/industry/industry_game.gd tests/test_industry_game.gd tests/test_industry_discovery.gd
git commit -m "feat: add depth milestones and persistent discoveries"
```

---

### Task 4: Exploration, sites permanents, capacité et Centre

**Files:**
- Modify: `src/industry/industry_game.gd`
- Modify: `tests/test_industry_game.gd`

**Interfaces:**
- Produces `total_capacity() -> int`.
- Produces `used_capacity() -> int`.
- Produces `center_upgrade_block_reason() -> String` and `upgrade_center() -> bool`.
- Produces `exploration_block_reason(discovery_id: String) -> String`, `start_exploration(discovery_id: String) -> bool`.
- Produces `site_toggle_block_reason(site_id: String, active: bool) -> String`, `set_site_active(site_id: String, active: bool) -> bool`.

- [ ] **Step 1: Tests atomiques capacité/Centre/exploration**

Ajouter :

```gdscript
var game = IndustryGame.new()
game.depth = 90
game.resources["iron"] = 1000
game.resources["coal"] = 1000
game.resources["iron_ingot"] = 100
game.resources["copper_ingot"] = 100
game.resources["cable"] = 100
t.check(game.upgrade_center(), "Centre 2 achetable")
t.check(game.upgrade_center(), "Centre 3 achetable")
t.check(game.upgrade_center(), "Centre 4 achetable")
t.check(game.total_capacity() == 6, "capacité Centre niveau 4")

game.permanent_sites = {
    "a": {"type": "crystal_cavern", "active": true, "capacity": 2, "rate": 0.03},
    "b": {"type": "ancient_structure", "active": true, "capacity": 2},
}
t.check(game.used_capacity() == 4, "capacité utilisée calculée")
```

Ajouter un test où l’activation d’un site de coût 3 échoue sans modifier l’état lorsque seulement 2 points sont libres.

- [ ] **Step 2: Vérifier l’échec**

Run suite ; Expected: FAIL sur méthodes manquantes.

- [ ] **Step 3: Implémenter Centre et capacité**

```gdscript
func total_capacity() -> int:
    var value := int(Catalog.CENTER_LEVELS[center_level]["capacity"])
    if "logistics_1" in built_technologies:
        value += int(Catalog.TECHNOLOGIES["logistics_1"]["effect"])
    if priority_branch == "logistics":
        value += int(Catalog.PRIORITY_BONUSES["logistics"]["capacity"])
    return value

func used_capacity() -> int:
    var total := 0
    for site in permanent_sites.values():
        if bool(site.get("active", false)):
            total += int(site.get("capacity", 0))
    return total
```

`upgrade_center()` prend `center_level + 1`, vérifie `depth >= CENTER_LEVELS[next]["depth"]`, vérifie le coût, dépense atomiquement puis incrémente.

- [ ] **Step 4: Implémenter exploration comme job indépendant**

Ajouter `explorations: Dictionary` au snapshot si ce champ n’a pas encore été introduit. Un job d’exploration :

```gdscript
{
    "discovery_id": discovery_id,
    "remaining": duration,
    "duration": duration,
}
```

Durée initiale data-driven : `60 s` pour `rich_vein`, `90 s` pour `unstable_cavity`, `180 s` pour `crystal_cavern`, `300 s` pour `ancient_structure`. Coût initial :

```gdscript
rich_vein: {"iron": 10}
unstable_cavity: {"iron": 12, "coal": 4}
crystal_cavern: {"iron_ingot": 3, "cable": 1}
ancient_structure: {"iron_ingot": 5, "copper_ingot": 3, "cable": 2}
```

À la fin : épuisable → créditer la récompense et `state = "exhausted"`; permanent → créer `permanent_sites[id]`, `state = "opened"`, actif par défaut uniquement si la capacité le permet.

- [ ] **Step 5: Ajouter production des sites permanents**

Dans chaque segment de `advance()`, produire le cristal des cavités actives :

```gdscript
if site["type"] == "crystal_cavern" and bool(site["active"]):
    var amount := float(site["rate"]) * seconds
    resources["crystal"] += amount
    _add_produced(produced, "crystal", amount)
```

- [ ] **Step 6: Vérifier et committer**

Run suite complète ; Expected: PASS.

Commit:

```bash
git add src/industry/industry_game.gd tests/test_industry_game.gd
git commit -m "feat: add exploration capacity and operations center"
```

---

### Task 5: Technologies, branches et priorité avec cooldown

**Files:**
- Modify: `src/industry/industry_game.gd`
- Modify: `tests/test_industry_game.gd`

**Interfaces:**
- Produces `technology_unlock_block_reason(id: String) -> String`, `unlock_technology(id: String) -> bool`.
- Produces `technology_build_block_reason(id: String) -> String`, `build_technology(id: String) -> bool`.
- Produces `priority_block_reason(branch: String) -> String`, `set_priority(branch: String) -> bool`.
- Produces `quality_floor() -> float`.

- [ ] **Step 1: Tests des trois branches**

```gdscript
var game = IndustryGame.new()
game.depth = 90
game.tech_points = 3
game.resources["iron_ingot"] = 100
game.resources["copper_ingot"] = 100
game.resources["cable"] = 100
game.resources["crystal"] = 100

t.check(game.unlock_technology("production_1"), "Production I débloquée")
t.check(game.build_technology("production_1"), "Production I construite")
var before := game.mine_rate("iron")
t.check(game.set_priority("production"), "priorité Production choisie")
t.check(game.mine_rate("iron") > before, "priorité Production augmente le débit")
t.check(not game.set_priority("exploration"), "cooldown empêche le changement immédiat")
game.advance(300.0)
t.check(game.set_priority("exploration"), "priorité change après 5 min")
t.check(game.quality_floor() >= 0.20, "priorité Exploration relève le plancher")
```

- [ ] **Step 2: Vérifier l’échec**

Run suite ; Expected: FAIL.

- [ ] **Step 3: Implémenter déblocage puis construction**

`unlock_technology()` exige profondeur >= 90, id connu, technologie non déjà débloquée, `tech_points >= 1`; il retire exactement 1 point et ajoute l’id à `unlocked_technologies`.

`build_technology()` exige id débloqué, non construit, ressources du coût disponibles ; il dépense puis ajoute à `built_technologies`.

- [ ] **Step 4: Appliquer les effets sans dupliquer les formules**

Créer :

```gdscript
func production_multiplier() -> float:
    var value := 1.0
    if "production_1" in built_technologies:
        value += 0.10
    if priority_branch == "production":
        value += 0.10
    return value

func quality_floor() -> float:
    var value := 0.0
    if "exploration_1" in built_technologies:
        value += 0.20
    if priority_branch == "exploration":
        value += 0.20
    return clampf(value, 0.0, 0.8)
```

Multiplier `mine_rate()` par `production_multiplier()`.

- [ ] **Step 5: Implémenter priorité et cooldown**

`set_priority()` accepte uniquement `production`, `logistics`, `exploration`; refuse si `priority_cooldown_remaining > 0`; change la branche et fixe `300.0`. Dans chaque segment de `advance()`, réduire ce cooldown de la durée avancée sans passer sous zéro.

- [ ] **Step 6: Vérifier et committer**

Run suite complète ; Expected: PASS.

Commit:

```bash
git add src/industry/industry_game.gd tests/test_industry_game.gd
git commit -m "feat: add technology branches and operating priority"
```

---

### Task 6: Événement Filon instable + comportement hors ligne

**Files:**
- Modify: `src/industry/industry_game.gd`
- Modify: `src/industry/industry_session.gd`
- Modify: `tests/test_industry_game.gd`
- Modify: `tests/test_industry_session.gd`

**Interfaces:**
- Produces `present_pending_event() -> bool`.
- Produces `event_choice_block_reason(resource_id: String) -> String`, `choose_event_resource(resource_id: String) -> bool`.
- `advance(seconds)` rapporte `events_queued` et `events_expired`.

- [ ] **Step 1: Tests événement actif et différé**

```gdscript
var game = IndustryGame.new()
game.pending_events.append({"type": "unstable_vein", "presented": false})
game.advance(3600.0)
t.check(game.active_event.is_empty(), "événement non présenté ne s’expire pas hors ligne")
t.check(game.pending_events.size() == 1, "événement reste en attente")
t.check(game.present_pending_event(), "événement présenté")
t.check(game.active_event["remaining"] == 300.0, "timer démarre à la présentation")
t.check(game.choose_event_resource("copper"), "choix cuivre accepté")
var rate := game.mine_rate("copper")
game.advance(299.0)
t.check(game.mine_rate("copper") == rate, "bonus actif avant expiration")
game.advance(1.0)
t.check(game.active_event.is_empty(), "événement expiré")
```

- [ ] **Step 2: Vérifier l’échec**

Run suite ; Expected: FAIL.

- [ ] **Step 3: Implémenter l’état événement**

À la résolution d’une `unstable_cavity`, ne pas démarrer le timer :

```gdscript
pending_events.append({"type": "unstable_vein", "presented": false})
```

`present_pending_event()` retire le premier élément, crée :

```gdscript
active_event = {
    "type": "unstable_vein",
    "presented": true,
    "choice": "",
    "remaining": float(Catalog.EVENTS["unstable_vein"]["duration"]),
    "duration": float(Catalog.EVENTS["unstable_vein"]["duration"]),
}
```

`choose_event_resource()` accepte seulement les trois ids listés dans le catalogue et uniquement si `choice == ""`.

- [ ] **Step 4: Appliquer le bonus au débit et l’expiration**

Dans `mine_rate(id)`, si l’événement actif a `choice == id`, appliquer `1.0 + rate_bonus` en multiplicateur temporaire. Dans `advance()`, le timer actif fait partie des prochaines bornes de segment afin qu’un grand saut et des petits sauts produisent le même résultat.

- [ ] **Step 5: Présenter les événements différés côté session**

Ajouter `event_available` signal ou réutiliser `changed`; après `initialize()`, conserver les événements hors ligne en attente. Exposer :

```gdscript
func present_pending_event() -> bool:
    advance_to(Time.get_unix_time_from_system())
    if not game.present_pending_event():
        return false
    persist()
    changed.emit()
    return true
```

Ne jamais appeler automatiquement cette méthode pendant l’absence.

- [ ] **Step 6: Vérifier équivalence temporelle et commit**

Ajouter un test comparant `advance(600)` à dix appels `advance(60)` avec événement actif. Run suite complète ; Expected: PASS.

Commit:

```bash
git add src/industry/industry_game.gd src/industry/industry_session.gd tests/test_industry_game.gd tests/test_industry_session.gd
git commit -m "feat: add unstable vein events and offline deferral"
```

---

### Task 7: Façade session complète et persistance après chaque décision

**Files:**
- Modify: `src/industry/industry_session.gd`
- Modify: `tests/test_industry_session.gd`

**Interfaces:**
- Produces session wrappers : `upgrade_center()`, `start_exploration(id)`, `set_site_active(id, active)`, `unlock_technology(id)`, `build_technology(id)`, `set_priority(branch)`, `choose_event_resource(id)`.

- [ ] **Step 1: Test façade/persistance**

Ajouter un test avec chemin de sauvegarde temporaire vérifiant qu’une action Centre ou technologie réussie est immédiatement retrouvée après rechargement.

- [ ] **Step 2: Vérifier l’échec**

Run suite ; Expected: FAIL sur wrappers manquants.

- [ ] **Step 3: Ajouter un helper d’action pour éviter la duplication**

```gdscript
func _apply_action(callable: Callable) -> bool:
    advance_to(Time.get_unix_time_from_system())
    if not callable.call():
        return false
    persist()
    changed.emit()
    return true
```

Utiliser ce helper pour les nouvelles méthodes et, si les tests restent verts, pour `upgrade_mine`, `upgrade_drill`, `start_excavation`, `start_batch`.

Exemple :

```gdscript
func upgrade_center() -> bool:
    return _apply_action(game.upgrade_center)

func set_site_active(id: String, active: bool) -> bool:
    return _apply_action(game.set_site_active.bind(id, active))
```

- [ ] **Step 4: Vérifier les notifications focus/close et commit**

Run suite complète ; Expected: PASS, y compris focus out, pause, close, autosave.

Commit:

```bash
git add src/industry/industry_session.gd tests/test_industry_session.gd
git commit -m "refactor: expose progression actions through industry session"
```

---

### Task 8: Découper l’UI en quatre écrans sans régression de gestion

**Files:**
- Create: `src/industry/ui/industry_panel.gd`
- Create: `src/industry/ui/center_panel.gd`
- Create: `src/industry/ui/technology_panel.gd`
- Modify: `src/industry/ui/industry_screen.gd`
- Modify: `tests/test_industry_ui.gd`

**Interfaces:**
- Chaque panel expose `bind_session(session) -> void` et `refresh() -> void`.
- `IndustryScreen` reste seul propriétaire de la navigation basse.

- [ ] **Step 1: Étendre le test UI aux quatre onglets**

Dans `tests/test_industry_ui.gd`, après instanciation réelle :

```gdscript
support.check(screen.find_child("TabMine", true, false) != null, "onglet Mine présent")
support.check(screen.find_child("TabIndustrie", true, false) != null, "onglet Industrie présent")
support.check(screen.find_child("TabCentre", true, false) != null, "onglet Centre présent")
support.check(screen.find_child("TabTechnologie", true, false) != null, "onglet Technologie présent")
```

Simuler un clic sur `TabIndustrie` et vérifier que `IndustryPanel.visible == true` et que les contrôles `FurnaceStart`, `WorkshopStart`, `MineUpgrade_iron` existent encore.

- [ ] **Step 2: Vérifier l’échec**

Run UI test réel :

```bash
godot --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_industry_ui.gd
```

Expected: FAIL sur onglets/panels.

- [ ] **Step 3: Extraire les widgets v0.2 dans `IndustryPanel`**

Déplacer la construction/refresh mines + fonderie + atelier depuis `IndustryScreen` sans changer leurs noms de nodes publics. `IndustryPanel.bind_session()` connecte `session.changed` à `refresh`.

- [ ] **Step 4: Créer `CenterPanel` et `TechnologyPanel` minimaux mais fonctionnels**

`CenterPanel` montre `Centre niveau X`, `Capacité utilisée/total`, coût du prochain niveau et bouton `CenterUpgrade`. Liste des sites permanents avec boutons `SiteToggle_<id>`.

`TechnologyPanel` montre `Points technologiques`, trois cartes Production/Logistique/Exploration, boutons `TechUnlock_<id>`, `TechBuild_<id>`, `Priority_<branch>`, et compteur de cooldown lorsqu’il est > 0.

- [ ] **Step 5: Refaire `IndustryScreen` comme shell**

Le shell contient : barre haute compacte, `ContentHost`, navigation basse. `Mine` sélectionné au démarrage. Les quatre boutons changent uniquement la visibilité des quatre vues ; ils ne recréent pas la session.

- [ ] **Step 6: Vérifier large/étroit et commit**

Run test UI en 1280×800 et 720×1000 via le mécanisme de capture existant. Expected: actions essentielles accessibles, aucun bouton principal hors écran.

Commit:

```bash
git add src/industry/ui/industry_screen.gd src/industry/ui/industry_panel.gd src/industry/ui/center_panel.gd src/industry/ui/technology_panel.gd tests/test_industry_ui.gd
git commit -m "feat: split industry UI into mine center and technology views"
```

---

### Task 9: Vue mine verticale interactive et panneaux contextuels

**Files:**
- Create: `src/industry/ui/mine_world.gd`
- Create: `src/industry/ui/site_panel.gd`
- Modify: `src/industry/ui/industry_screen.gd`
- Modify: `src/industry/ui/industry_theme.gd`
- Modify: `tests/test_industry_ui.gd`

**Interfaces:**
- `MineWorld.bind_session(session) -> void`.
- `MineWorld.focus_depth(depth: int) -> void`.
- Signal `selection_changed(kind: String, id: String)`.
- `SitePanel.show_selection(kind: String, id: String, session) -> void`.

- [ ] **Step 1: Écrire les tests caméra et sélection**

Vérifier :

```gdscript
var mine = screen.find_child("MineWorld", true, false)
support.check(mine != null, "vue mine verticale présente")
support.check(mine.get("min_zoom") >= 0.7, "zoom minimum borné")
support.check(mine.get("max_zoom") <= 1.25, "zoom maximum borné")
```

Créer une partie de test avec découverte 30 m et vérifier qu’un hit target nommé `Discovery_<id>` existe et qu’un clic affiche `ContextPanel`.

- [ ] **Step 2: Vérifier l’échec**

Run UI test ; Expected: FAIL sur `MineWorld`.

- [ ] **Step 3: Implémenter le monde vertical comme `Control` dessiné + enfants interactifs**

`MineWorld` conserve :

```gdscript
var min_zoom := 0.75
var max_zoom := 1.15
var zoom := 1.0
var scroll_depth := 0.0
var velocity := 0.0
const PIXELS_PER_METER := 7.0
```

Le glisser vertical modifie `scroll_depth`, la molette/pincement modifie `zoom` clampé. Le rendu dessine la surface à y=0 puis les couches à `depth * PIXELS_PER_METER`. Le mouvement horizontal reste absent dans cette première implémentation ; les poches gauche/droite sont placées dans la largeur visible.

- [ ] **Step 4: Représenter au minimum trois zones visuelles**

Palette initiale :

```gdscript
0..59 m   -> roche #343b40, ambre industriel
60..89 m  -> roche dense #252f38, lumière froide secondaire
90..149 m -> roche #1b2933, cyan cristal possible
150 m     -> roche #14212b, cyan/turquoise plus présent
```

Surface : silhouettes modulaires Base/Centre/Atelier/Stockage. Sites : plateformes simples, convoyeurs et marqueurs. Pas d’asset peint unique requis dans cette tâche.

- [ ] **Step 5: Ajouter les interactions monde**

Créer des boutons/Areas transparents nommés : `Mine_<id>`, `Drill`, `Discovery_<id>`, `Site_<id>`. Leur clic émet `selection_changed`. `IndustryScreen` transmet la sélection à `SitePanel`.

- [ ] **Step 6: Ajouter raccourcis de caméra**

Boutons `FocusSurface`, `FocusDrill` et, après 90 m, raccourcis 30/60/90/120/150 visibles selon profondeur atteinte. `focus_depth()` anime ou positionne sans modifier l’état logique.

- [ ] **Step 7: Vérifier et committer**

Run UI large/étroit + suite headless ; Expected: PASS.

Commit:

```bash
git add src/industry/ui/mine_world.gd src/industry/ui/site_panel.gd src/industry/ui/industry_screen.gd src/industry/ui/industry_theme.gd tests/test_industry_ui.gd
git commit -m "feat: add interactive vertical mine world"
```

---

### Task 10: Panneaux contextuels réellement actionnables

**Files:**
- Modify: `src/industry/ui/site_panel.gd`
- Modify: `src/industry/ui/mine_world.gd`
- Modify: `tests/test_industry_ui.gd`

**Interfaces:**
- Le panneau appelle uniquement `IndustrySession`, jamais `IndustryGame` directement pour une mutation.

- [ ] **Step 1: Tests de clics réels**

Exercer successivement : mine de fer → amélioration, foreuse → lancement, découverte → exploration, site permanent → activation/désactivation. Vérifier que l’état de `session.game` change après chaque clic et que les boutons sont désactivés avec un motif lisible quand l’action est impossible.

- [ ] **Step 2: Vérifier l’échec**

Run UI test ; Expected: FAIL sur au moins les nouvelles actions contextuelles.

- [ ] **Step 3: Implémenter les quatre familles de panneaux**

Contenu exact :

```text
Mine : nom, niveau, production/min, coût prochain niveau, AMÉLIORER
Foreuse : niveau, cible, durée, progression, AMÉLIORER / FORER
Découverte : indice, profondeur, coût, durée, EXPLORER
Site permanent : nom, production/effet, coût capacité, ACTIVER/DÉSACTIVER
```

Les noms de boutons publics sont `ContextPrimary` et `ContextSecondary`; leur callback est remplacé à chaque sélection et appelle les wrappers de session.

- [ ] **Step 4: Afficher les timers dans le monde**

Pour forage/exploration/production active, ajouter près du site un label `mm:ss` et une barre compacte. Ces widgets lisent `remaining/duration` ; ils ne déclenchent aucune récompense.

- [ ] **Step 5: Vérifier et committer**

Run UI + headless ; Expected: PASS.

Commit:

```bash
git add src/industry/ui/site_panel.gd src/industry/ui/mine_world.gd tests/test_industry_ui.gd
git commit -m "feat: make mine world interactions actionable"
```

---

### Task 11: Présentation d’événement et bilan hors ligne dans le nouveau HUD

**Files:**
- Modify: `src/industry/ui/industry_screen.gd`
- Modify: `src/industry/ui/site_panel.gd`
- Modify: `tests/test_industry_ui.gd`

**Interfaces:**
- Aucun nouvel état logique ; consomme `session.game.pending_events`, `active_event`, `offline_report`.

- [ ] **Step 1: Tests de présentation non punitive**

Créer une session test avec `pending_events = [{"type":"unstable_vein","presented":false}]`. Vérifier qu’une bannière `PendingEventBanner` apparaît sans masquer la mine ; cliquer ouvre le choix Fer/Cuivre/Charbon et démarre alors seulement le timer.

- [ ] **Step 2: Vérifier l’échec**

Run UI test ; Expected: FAIL.

- [ ] **Step 3: Ajouter la bannière événement**

Texte : `Filon instable détecté — choisir une priorité d’exploitation`. Bouton principal : `VOIR`. Une fois présenté, panneau avec trois boutons `Event_iron`, `Event_copper`, `Event_coal`, puis affichage du temps restant et de la ressource choisie.

- [ ] **Step 4: Replacer le bilan hors ligne**

Le bilan v0.2 reste non bloquant. Dans le nouveau shell, afficher une carte compacte sous la barre haute pendant quelques secondes ou jusqu’à fermeture manuelle ; contenu : durée absence, ressources produites, travaux terminés, profondeur gagnée, événements mis en attente.

- [ ] **Step 5: Vérifier et committer**

Run UI large/étroit ; Expected: PASS.

Commit:

```bash
git add src/industry/ui/industry_screen.gd src/industry/ui/site_panel.gd tests/test_industry_ui.gd
git commit -m "feat: surface offline progress and strategic events"
```

---

### Task 12: Vie visuelle modulaire et états animés

**Files:**
- Modify: `src/industry/ui/mine_world.gd`
- Modify: `src/industry/ui/industry_theme.gd`
- Modify: `tests/test_industry_ui.gd`

**Interfaces:**
- Les animations consomment uniquement l’état logique déjà exposé.

- [ ] **Step 1: Test d’états visuels minimaux**

Vérifier que les nodes décoratifs correspondant à un forage actif, une mine active et une cavité cristalline active changent d’état ou de propriété d’animation lorsque le modèle change. Le test ne compare pas des pixels exacts ; il vérifie les flags/nodes et produit des captures pour inspection humaine.

- [ ] **Step 2: Vérifier l’échec**

Run UI test ; Expected: FAIL sur marqueurs d’animation.

- [ ] **Step 3: Ajouter animation d’ascenseur et convoyeurs**

Dans `_process(delta)`, animation purement visuelle : phase cyclique basée sur `Time.get_ticks_msec()` ou delta visuel, jamais utilisée pour l’économie. Désactiver ou ralentir les animations d’un site lorsque `active == false`.

- [ ] **Step 4: Ajouter les marqueurs de profondeur**

Surface/couches hautes : ambre et acier. À partir de 90 m : cristaux cyan possibles. Anomalie : halo violet réservé aux poches concernées. À 150 m : arrière-plan plus sombre et présence turquoise renforcée.

- [ ] **Step 5: Garder la densité maîtrisée**

Maximum initial visible simultanément par tranche : 1 ascenseur principal, 2 convoyeurs animés, 1 véhicule/wagonnet mobile, 3–6 silhouettes d’équipes. Ne pas créer de simulation individuelle d’ouvrier.

- [ ] **Step 6: Vérifier les captures et committer**

Run capture 1280×800 et 720×1000. Inspecter : mine dominante, HUD lisible, pas de surcharge, profondeur reconnaissable.

Commit:

```bash
git add src/industry/ui/mine_world.gd src/industry/ui/industry_theme.gd tests/test_industry_ui.gd
git commit -m "feat: add modular life and depth art states"
```

---

### Task 13: Parcours d’acceptation v0.3 et CI finale

**Files:**
- Create: `tests/test_progression_acceptance.gd`
- Modify: `tests/test_runner.gd`
- Modify: `tests/test_industry_ui.gd`
- Modify: `.github/workflows/godot-tests.yml`
- Modify: `README.md`

**Interfaces:**
- Aucun nouveau contrat gameplay ; verrouille le comportement livré.

- [ ] **Step 1: Écrire le parcours déterministe d’acceptation**

Le test doit construire une partie sans debug UI et vérifier ce parcours logique : production de base → forage 30 m → découverte → exploration → Centre 2 → progression 60 m → foreuse suffisante → 90 m → point techno → Centre 4 → cavité cristalline garantie → activation selon capacité → priorité → technologie → Filon instable → sauvegarde/rechargement sans duplication.

Extrait de structure :

```gdscript
extends RefCounted

const Game = preload("res://src/industry/industry_game.gd")

func run(t) -> void:
    var game = Game.new()
    game.resources["iron"] = 10000.0
    game.resources["coal"] = 10000.0
    game.resources["copper"] = 10000.0
    game.resources["iron_ingot"] = 1000.0
    game.resources["copper_ingot"] = 1000.0
    game.resources["cable"] = 1000.0
    # Le test utilise les API publiques pour atteindre les seuils ; aucune mutation directe de profondeur après cette préparation économique.
    t.check(game.start_excavation(), "premier forage lancé")
```

Pour accélérer le test, appeler `advance(game.jobs["drill"]["remaining"])` au lieu d’attendre le temps réel.

- [ ] **Step 2: Ajouter la suite au runner et vérifier l’échec avant finalisation**

Ajouter :

```gdscript
preload("res://tests/test_progression_acceptance.gd"),
```

Run suite ; Expected: le test révèle toute API ou condition manquante, à corriger dans la tâche correspondante avant commit final.

- [ ] **Step 3: Étendre la CI**

Conserver l’import headless, la suite headless et l’exercice UI réel. Ajouter la branche `feature/progression-v0.3` aux déclencheurs si nécessaire et conserver l’upload des captures `industry-ui`.

- [ ] **Step 4: Mettre à jour README**

Documenter : progression jusqu’à 150 m, Centre/capacité, poches, cristal brut, technologies, priorité, événements, navigation Mine/Industrie/Centre/Technologie, migration automatique v1→v2, commandes de tests.

- [ ] **Step 5: Vérification finale complète**

Run:

```bash
godot --headless --editor --quit --path .
godot --headless --path . -s res://tests/test_runner.gd
xvfb-run -a godot --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_industry_ui.gd -- --screenshots /tmp/digger-v03-ui
```

Expected:
- import sans `SCRIPT ERROR` ni `ERROR:` ;
- toutes les suites v0.1/v0.2/v0.3 PASS ;
- parcours UI avec vrais clics PASS ;
- captures large et étroite créées ;
- aucune perte d’action essentielle sous 1000 px ;
- migration v1 testée ;
- sauvegarde invalide préservée ;
- gros saut temporel équivalent aux petits sauts.

- [ ] **Step 6: Commit final de documentation/acceptation**

```bash
git add tests/test_progression_acceptance.gd tests/test_runner.gd tests/test_industry_ui.gd .github/workflows/godot-tests.yml README.md
git commit -m "test: lock progression v0.3 acceptance flow"
```

---

## Ordre d’exécution et gates

1. Tasks 1–3 : fondation données, save v2, profondeur/découvertes.
2. Tasks 4–7 : exploration, capacité, Centre, technologie, événement, session.
3. Gate logique : suite headless entièrement verte avant toute refonte majeure UI.
4. Tasks 8–11 : shell UI, vue mine, interactions, événement/bilan.
5. Gate UI : parcours réel large + étroit vert.
6. Task 12 : enrichissement visuel uniquement après stabilité des interactions.
7. Task 13 : acceptation, CI et documentation.

## Self-review du plan

- Couverture spec : progression 30/60/90/120/150, découverte persistante, cristal, Centre 1–6, capacité, sites permanents, trois technologies, trois priorités, cooldown 5 min, Filon instable, hors ligne, migration, vue verticale, interactions directes, quatre onglets, animations modulaires et CI sont tous rattachés à une tâche.
- Aucune logique économique n’est confiée au rendu.
- La migration arrive avant que le nouveau schéma ne soit utilisé comme seule forme persistée.
- Les fonctions publiques utilisées par l’UI passent par `IndustrySession` pour sauvegarder immédiatement après décision.
- Les valeurs d’équilibrage initiales sont centralisées dans le catalogue et pourront être ajustées sans toucher à l’UI.
- Aucun timer obligatoire de plusieurs heures, aucune ressource supplémentaire autre que `crystal`, aucun système hors périmètre n’est introduit.
