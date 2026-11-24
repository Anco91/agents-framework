# Guide d'utilisation

Ce guide explique comment installer et utiliser `agents-framework` sur un projet, du premier
`init.sh` jusqu'à la première sous-spec livrée. Pour le pourquoi et la vue d'ensemble, voir le
[`README`](../README.md). Pour les décisions de conception, voir
[`docs/decisions-log.md`](decisions-log.md).

## 1. Prérequis

- `bash` (macOS 3.2 ou Linux), `git`.
- Un hôte agent : Kilo Code, Claude Code, Aider, Codex, OpenCode, etc.
- Aucune dépendance runtime : pas de `jq`, pas de Python, pas de réseau.

Vérifier :

```bash
bash --version
git --version
```

## 2. Installer le cadre dans un projet

Cloner le cadre une fois :

```bash
git clone https://github.com/Anco91/agents-framework.git ~/agents-framework
```

Puis l'installer dans le projet cible, neuf ou existant :

```bash
~/agents-framework/init.sh install /chemin/du/projet --host kilo,claude,skills
```

Choisir les hôtes utiles :

| Hôte | Fichiers créés |
|---|---|
| `claude` | `CLAUDE.md` |
| `kilo` | `.kilo/agents/agents-fw-advisor.md`, `agents-fw-executor.md`, exemple `kilo.jsonc` |
| `aider` | `.aider.conf.yml` |
| `skills` | `.agents/skills/agents-fw-<procédure>/SKILL.md` |

Sans `--host`, seuls le bloc géré et `.agents-fw/` sont installés. `init.sh hosts` liste les
fichiers de chaque hôte.

Ce que l'installation fait :

- ajoute un bloc géré dans `AGENTS.md`, entre `<!-- agents-fw:start -->` et `<!-- agents-fw:end -->` ;
- copie règles, standards, procédures, templates et scripts dans `.agents-fw/` ;
- crée `ARCHITECTURE.md`, `specs/SPEC_MASTER.md` et `docs/handoffs/` s'ils manquent ;
- ne touche pas au reste de `AGENTS.md`, ni à `openspec/`, ni à `skills/`.

## Adopter dans un projet existant

Un projet qui a déjà des règles d'agent (Claude, Cursor, Kilo, Copilot, Aider) passe au cadre sans rien perdre.

```bash
./init.sh adopt /chemin/vers/projet --host claude          # simulation : ne change aucun fichier
./init.sh adopt /chemin/vers/projet --host claude --apply  # sauvegarde puis installe
```

La simulation affiche `would move <chemin>` pour chaque élément, `left alone` pour `.claude/settings.json` et
`.mcp.json`, puis le contenu des fichiers concernés : l'Advisor y reprend les faits du projet (build, stack,
domaine) dans `ARCHITECTURE.md`. Avec `--apply`, chaque élément est déplacé (jamais supprimé) vers
`.agents-fw/backup/<horodatage>/` avec le même chemin relatif, puis l'installation habituelle s'exécute.
Un second `--apply` n'a rien à déplacer : `nothing to adopt`.

Éléments déplacés : `CLAUDE.md`, le contenu de `.claude/rules`, `.claude/agents` et `.claude/skills`,
`.cursorrules`, le contenu de `.cursor/rules` et `.kilocode/rules`, `.github/copilot-instructions.md`,
`CONVENTIONS.md`. Les noms en `agents-fw-` et un `CLAUDE.md` identique à celui du cadre sont ignorés.

### Étapes manuelles (jamais touchées par `adopt`)

- `.claude/settings.json` : ouvrir le fichier et ajouter à la main le hook PostToolUse de
  `adapters/claude/settings.example.json` (clé `hooks`), sans écraser vos permissions. Pas de `jq` requis.
- `.mcp.json` : conservé tel quel ; vérifier simplement que les serveurs MCP restent valides.
- `~/.claude` (règles globales) : non modifié. Ces règles ne remplacent pas TEST-1..3 ni la séparation des rôles
  (voir `core.md`) ; retirez celles qui les contredisent.

### Nouveau projet

Pas de fichiers existants : `./init.sh install /chemin/vers/projet`, puis la section 2.

### Restaurer

La sauvegarde est faite de fichiers ordinaires : `mv .agents-fw/backup/<horodatage>/<chemin> <chemin>` pour
remettre un fichier à sa place d'origine.

## 3. Vérifier l'installation

```bash
cd /chemin/du/projet
bash .agents-fw/scripts/arch-check.sh ARCHITECTURE.md
bash .agents-fw/scripts/lint-docs.sh .agents-fw
```

Les deux commandes doivent sortir avec le code 0. `arch-check` échoue tant que le registre de
`ARCHITECTURE.md` ne couvre pas les dossiers déclarés : c'est normal au premier lancement.

## 4. Remplir `ARCHITECTURE.md`

C'est la carte que lit l'agent avant toute recherche. Trois sections comptent :

1. **Module map** : une ligne par module, son rôle, ses collaborateurs.
2. **Declared folders** : les dossiers de code réutilisable, un par ligne, terminés par `/`.
3. **Reuse registry** : chaque fichier ou dossier déclaré, avec son type et son usage.

Exemple minimal :

```markdown
## Declared folders

- `src/domain/`
- `src/server/`

## Reuse registry

| Path | Kind | Purpose |
|---|---|---|
| `src/domain/` | folder | Règles métier pures |
| `src/server/` | folder | Services et accès base |
```

Puis :

```bash
bash .agents-fw/scripts/arch-check.sh ARCHITECTURE.md
```

Un fichier non déclaré dans un dossier déclaré fait échouer la commande. Le registre reste vrai
dans le même commit que le code.

## 5. Écrire la première sous-spec (rôle Advisor)

Utiliser un modèle fort, en session courte. Le prompt type :

```text
Rôle : Advisor.
Lis AGENTS.md, ARCHITECTURE.md, specs/SPEC_MASTER.md.
Écris specs/01-<slug>.md à partir de .agents-fw/templates/SUB_SPEC.md.
Une seule livraison observable. Cadre complet : créer, modifier, lire, réutiliser,
librairies, interdits. Écris les tests verrouillés et prouve qu'ils échouent.
Ne touche à aucun fichier hors de la sous-spec et des tests.
```

Le **Cadre** doit permettre à un Executor peu cher de coder sans ouvrir un fichier hors de la
liste de lecture, sans choisir un nom, un chemin ou une librairie.

Règles utiles :

- une sous-spec = une branche = une PR ;
- une sous-spec ≤ ~150 lignes et ≤ ~8 fichiers de production ;
- seulement la prochaine sous-spec est détaillée ; les suivantes restent des lignes d'index.

## 6. Verrouiller les tests

L'Advisor écrit les tests avant le code. Ils doivent échouer. Puis il renseigne l'en-tête :

```yaml
status: ready
locked_at: <sha du commit qui contient les tests>
locked_tests:
  - tests/test_<slug>.sh
```

Vérifier :

```bash
bash .agents-fw/scripts/test-lock.sh specs/01-<slug>.md
```

Le script échoue si un test verrouillé a changé depuis `locked_at`.

## 7. Valider la sous-spec

C'est le seul point de contrôle humain obligatoire avant l'exécution. Vérifier :

- le résultat attendu est observable et petit ;
- le Cadre liste tous les fichiers nécessaires ;
- les tests couvrent chaque critère d'acceptation ;
- rien d'important n'est hors périmètre.

Puis créer un handoff vers l'Executor :

```bash
bash .agents-fw/scripts/new-handoff.sh specs/01-<slug>.md
```

Remplir le fichier produit dans `docs/handoffs/`, puis coller le bloc final dans une session
neuve :

```text
NEXT SESSION
Role: executor
Read: AGENTS.md, ARCHITECTURE.md, docs/handoffs/<date>-01-<slug>.md
Sub-spec: specs/01-<slug>.md (master: specs/SPEC_MASTER.md)
First action: <une phrase>
```

## 8. Exécuter (rôle Executor)

Modèle Flash, session neuve, aucune conversation précédente. Prompt type :

```text
Rôle : Executor.
Lis uniquement le handoff, la sous-spec et les fichiers de sa section Read.
Implémente le Cadre. Ne modifie aucun test verrouillé.
Lance les tests. Si le Cadre est ambigu, arrête-toi et signale-le.
```

Contrôles après exécution :

```bash
bash .agents-fw/scripts/test-lock.sh specs/01-<slug>.md
bash .agents-fw/scripts/arch-check.sh ARCHITECTURE.md
```

L'Executor peut proposer de nouveaux tests, jamais modifier un test verrouillé. Un test qui semble
faux se traite dans la section « Test change requests » de la sous-spec : seul l'Advisor le corrige,
puis le reverrouille.

## 9. Revue et livraison

Faire relire par une autre famille de modèle :

```text
Rôle : Reviewer.
Vérifie le diff contre le Cadre, les critères d'acceptation et les standards.
Lance test-lock, arch-check et les tests. Une ligne par écart, avec correctif.
```

Puis :

1. mettre à jour `ARCHITECTURE.md` si le code ajoute un module ou une réutilisation ;
2. mettre à jour la ligne de la sous-spec dans `specs/SPEC_MASTER.md` ;
3. ouvrir la PR avec le trailer `Spec: specs/01-<slug>.md` ;
4. écrire le handoff de livraison et terminer la session par le bloc `NEXT SESSION`.

## 10. Mettre à jour le cadre

```bash
cd ~/agents-framework && git pull
./init.sh update /chemin/du/projet
```

- Un fichier du cadre modifié localement est conservé ; la nouvelle version arrive en `.new`.
- `--force` remplace les fichiers modifiés.
- Les fichiers retirés en amont sont supprimés seulement s'ils n'ont pas été modifiés localement.

## 11. Petite correction sans spec

Pour ≤ 3 fichiers, sans nouveau module ni règle métier :

```bash
git commit -m "fix: <résumé>" -m "Track: fast"
```

Retrouver ces commits :

```bash
git log --grep "Track: fast"
```

Tout le reste passe par une sous-spec.

## Politique d'outils

Ordre de choix (CTX-8) : registre de `ARCHITECTURE.md`, puis lecture par plage ou LSP/Serena, puis
recherche limitée à un dossier déclaré, puis Context7 ou la doc officielle pour les API de
bibliothèques.

Avec l'hôte `claude`, `init.sh` copie deux exemples dans `.agents-fw/adapters/claude/` :
`settings.example.json` (clé `permissions.deny`) et `mcp.example.json` (serveur Context7). Le cadre
ne crée ni ne modifie jamais `.claude/settings.json` ni `.mcp.json`. Fusion à la main, sans `jq` :

1. Ouvrir `.claude/settings.json` (le créer s'il n'existe pas).
2. Copier le tableau `deny` de l'exemple dans `permissions.deny`, en gardant vos entrées existantes.
3. Copier l'entrée `context7` de `mcp.example.json` dans `mcpServers` de `.mcp.json`.
4. Vérifier que chaque fichier reste du JSON valide (virgules, accolades).

Kilo et Aider ne sont pas couverts par cette politique.

## Coexister avec OpenSpec

OpenSpec est le format de spec **par défaut** (WF-9). Une sous-spec est un *change* OpenSpec :
`openspec/changes/<id>/` contient `proposal.md`, les deltas `specs/`, `design.md` et `tasks.md`, plus un
`frame.md` du cadre (en-tête `id`, `tier`, `locked_at`, `locked_tests`, Cadre, tests). Les scripts
(`test-lock.sh`, `new-handoff.sh`) prennent le chemin de ce `frame.md`.

Le flux ne s'arrête pas : explorer, proposer, dérouler `tasks.md`, archiver
(`.agents-fw/procedures/openspec-flow.md`). Les skills `openspec-*` viennent d'OpenSpec lui-même.

`init.sh` ne touche jamais au dossier `openspec/` et ne lance jamais `npx` : `install` et `update` le
laissent identique, octet par octet. C'est l'agent (ou toi) qui initialise OpenSpec une fois par projet.

Marche à suivre :

1. Dans le projet : `openspec init --tools claude` (ou `npx -y @fission-ai/openspec@latest init --tools claude`).
   Sans node, le cadre retombe sur le gabarit `SUB_SPEC.md` dans `specs/`.
2. Dans `specs/SPEC_MASTER.md`, la colonne Sous-spec pointe vers `openspec/changes/<id>/frame.md`.
3. Après `archive`, OpenSpec déplace le dossier vers `openspec/changes/archive/<date>-<id>/` : mettre à
   jour le chemin du master dans le même commit. L'`id` ne change jamais.

## 12. Protections de coût

- Une clé OpenRouter par outil, avec plafond de crédit.
- Suivre `Activity`, pas seulement le solde.
- Rôles par capacité, jamais par slug figé.
- Complétion locale ou Copilot, jamais un modèle de chat payant.
- Pas de mode Orchestrator Kilo.
- Handoff dès qu'un seuil SES-2 est atteint : ~30 échanges, ~40 appels d'outils, 3 échecs
  identiques, fichier hors Cadre, test douteux, ou demande humaine.

## 13. Dépannage

| Symptôme | Cause probable | Correctif |
|---|---|---|
| `AGENTS.md has malformed agents-fw markers` | marqueurs dupliqués ou inversés | garder un seul couple start/end, relancer `init.sh update` |
| `unregistered file: ...` | fichier ajouté dans un dossier déclaré | l'ajouter au registre ou le sortir du dossier |
| `registry path does not exist` | fichier déplacé | corriger `ARCHITECTURE.md` |
| `test-lock` échoue | test verrouillé modifié | restaurer le test, ou laisser l'Advisor le corriger et reverrouiller |
| fichier `.new` après `update` | fichier local modifié | comparer, puis `--force` si la version locale doit disparaître |
| `NEXT SESSION block differs` | template et procédure handoff divergents | resynchroniser `framework/templates/HANDOFF.md` et `framework/procedures/handoff.md` |

## 14. Ce dépôt se mange sa propre cuisine

Ce dépôt est lui-même un projet pilote :

- [`ARCHITECTURE.md`](../ARCHITECTURE.md) : registre du framework ;
- [`specs/SPEC_MASTER.md`](../specs/SPEC_MASTER.md) : index des sous-specs ;
- [`specs/01-lint-docs-line-count.md`](../specs/01-lint-docs-line-count.md) : première sous-spec ;
- [`docs/handoffs/`](handoffs/) : handoffs Advisor → Executor → Advisor.

Les scripts sont lancés directement depuis `framework/scripts/`, sans copie `.agents-fw/` : la
source de vérité reste `framework/`.

## 15. Références

| Sujet | Fichier |
|---|---|
| Règles workflow, rôles, sessions, tests | `framework/rules/` |
| Standards et code de référence | `framework/standards/` |
| Pas-à-pas Advisor, Executor, Reviewer | `framework/procedures/` |
| Templates de documents | `framework/templates/` |
| Scripts de contrôle | `framework/scripts/` |
| Hôtes et preuves | [`docs/hosts.md`](hosts.md) |
| Décisions et mesures | [`docs/decisions-log.md`](decisions-log.md) |
