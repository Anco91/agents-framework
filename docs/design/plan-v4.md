# Plan d'implémentation — `agents-framework` v4

Spec : `docs/design/spec-v4.md` (v4.1).
Remplace le plan v3. Prérequis : spec v4 validée par Anco (M0).

## Règles du plan

- Un jalon = une branche `feat/mX-<slug>` = une PR = une session (WF-3, GIT-1, SES-7).
- Chaque jalon s'ouvre par sa sous-spec `specs/mX-<slug>.md` (template SUB_SPEC dès M3 ; avant, format libre court).
- Les fichiers de règles et de standards (M1 à M3, M8) sont rédigés par l'Advisor (DD9).
  L'Executor ne code que les scripts et le code de référence, sous Cadre.
- Tests de comportement seulement : un script s'exécute sur un projet temporaire et on vérifie l'état
  produit. Les documents ne sont vérifiés que par `lint-docs.sh` (structure), pas par des `grep` de mots.
- Fin de chaque jalon : tests verts, PR, handoff au format SES-4.

## M0 — Spec master et journal des décisions

Fichiers : `docs/design/spec-v4.md`, `docs/decisions-log.md`.

1. Anco valide ou corrige la spec v4 ; réponses aux questions Q1 à Q4.
2. Extraire de `context-projet.md` (hors dépôt) dans `docs/decisions-log.md` (< 150 l.) :
   diagnostic 6 $ / 2 h (boucle agentique, pas l'autocomplétion), trois corrections de Mistral sur Qwen,
   rôles de modèles par capacités, tableau choisi/rejeté (Kilo Orchestrator, Copilot BYOK, T3 Code,
   `openrouter/free`, compaction), sélection MCP (Context7, GitHub, Serena), protections financières.
3. `git init`, `VERSION` = `0.1.0`, `CHANGELOG.md`, `.editorconfig`, `.gitignore` (`*.new`, `.env*`).

Fait quand : spec en statut « validée », journal < 150 lignes, premier commit.

## M1 — Cœur et règles

Fichiers : `framework/core.md`, `framework/rules/{workflow,roles,session,testing,context,git}.md`.

1. Rédiger chaque règle du §6.1 à §6.6 de la spec, une fois, avec son identifiant, son niveau,
   une phrase `why`, un exemple court conforme et un non conforme quand c'est utile.
2. `core.md` : identité, ordre de lecture, règles MUST résumées, table de routage, précédence (spec §7).
3. Relecture croisée par un modèle d'une autre famille (ROLE-5) : contradictions, ambiguïtés,
   règles non vérifiables.

Fait quand : `core.md` ≤ 120 lignes, chaque fichier ≤ 200 lignes, aucune règle dupliquée
(vérification manuelle ici, automatisée en M6).

## M2 — Standards et code de référence

Fichiers : `framework/standards/{architecture,backend,frontend,libraries,typescript,python}.md`.

1. Rédiger §6.7 à §6.10 de la spec avec les profils d'architecture et le registre LIB.
2. Code de référence, court et complet, dans les standards :
   - backend : `filterSchema` + `querySchema(fields)`, `queryToPrisma(query)` (where, orderBy, curseur),
     `createCrudService(model, schemas)`, route Next.js `GET/POST` + `[id]` `GET/PATCH/DELETE` ;
   - frontend : `createQueries(resource)` → `queryOptions` list/detail, `Guard` générique
     (`queries: QueryOptions[]`, `Suspense`, error boundary, `HydrationBoundary`), Content avec
     `useSuspenseQuery`, kit `Form` (`Form`, `FormTitle`, `FormFields`, `FormActions` avec modes
     `create | edit`, bouton supprimer standard), `PageLayout`, `DetailView`, `ListView` ;
   - python : schéma de filtre Pydantic, traducteur SQLAlchemy, routeur CRUD FastAPI.
3. Vérification du code de référence : l'Executor le colle dans un projet témoin temporaire
   (Next.js 16, React 19, TanStack Query 5, RHF 7, Zod 4, Prisma) et lance `tsc --noEmit` ;
   tests unitaires du traducteur de filtre (P2). Rien de ce projet témoin n'est commité.

Fait quand : code de référence compilé sans erreur, tests du traducteur verts, fichiers ≤ 200 lignes
(code de référence trop long → `standards/reference/*.md`).

## M3 — Templates, procédures, exemples

Fichiers : `framework/templates/{SPEC_MASTER,SUB_SPEC,ARCHITECTURE,HANDOFF,PR}.md`,
`framework/procedures/*.md`, `framework/examples/{good,bad}-sub-spec.md`.

1. Templates selon spec §7 ; en-tête de `SUB_SPEC.md` en front-matter simple `clé: valeur`
   (lisible par `test-lock.sh` sans parseur YAML).
2. Procédures pas à pas, chacune ≤ 80 lignes, qui citent les règles par identifiant.
3. `good-sub-spec.md` : sous-spec complète d'une vraie petite feature (ex. filtre par période sur une
   liste), Cadre, tests verrouillés, une demande de modification de test traitée, un handoff.
   `bad-sub-spec.md` : la même, avec les défauts annotés (découpage par couche, pas de Cadre,
   critères non observables, tests d'UI).
4. Migrer les sous-specs M0 à M2 de ce dépôt vers le template (le dépôt mange sa propre cuisine).

Fait quand : l'exemple contient chaque section obligatoire du template.

## M4 — `init.sh install`

Fichiers : `init.sh`, `tests/lib.sh`, `tests/test_install.sh`.

Cadre pour l'Executor :
- bash 3.2, `set -eu`, fonctions courtes ; `sha256()` qui utilise `sha256sum` ou `shasum -a 256` ;
  aucune lecture interactive.
- Fonctions : `usage`, `resolve_project` (refus `/`, `$HOME`, absent), `copy_framework`,
  `write_managed_block` (insère ou remplace entre marqueurs, crée `AGENTS.md` si absent),
  `create_project_files` (si absents), `write_manifest`.

Tests (écrits d'abord, verrouillés) :
- argument manquant, `/`, `$HOME`, dossier absent → code 1, aucun fichier créé ;
- projet vide → `.agents-fw/`, `AGENTS.md` avec bloc, `ARCHITECTURE.md`, `specs/SPEC_MASTER.md`,
  `docs/handoffs/`, `MANIFEST` avec la version ;
- `AGENTS.md` existant → contenu hors bloc identique octet par octet ;
- projet avec `skills/` et `.kilo/` (copie réduite de `mbongo`) → inchangés ;
- `ARCHITECTURE.md` existant → jamais réécrit ;
- second install → se comporte comme update, aucune duplication du bloc.

## M5 — `init.sh update`

Fichiers : `init.sh`, `tests/test_update.sh`.

Tests (verrouillés) : fichier inchangé → remplacé ; modifié → conservé + `.new` + avertissement ;
retiré en amont et inchangé → supprimé ; retiré et modifié → conservé + avertissement ;
bloc géré réécrit, reste d'`AGENTS.md` intact ; fichiers projet intacts ; interruption simulée
(fichier source illisible) → code 1, ancien manifest conservé, update suivant termine.

## M6 — Scripts de contrôle

Fichiers : `framework/scripts/{arch-check,test-lock,new-handoff,lint-docs}.sh`, tests associés.

- `test-lock.sh <sous-spec>` : lit `locked_tests` et `locked_at` ; échoue si
  `git diff --quiet <locked_at> -- <fichiers>` échoue ou si un fichier verrouillé a disparu.
  Tests : inchangé → 0 ; modifié → 1 ; supprimé → 1 ; en-tête absent → 1 avec message.
- `arch-check.sh` : lit la section « Dossiers déclarés » et le registre d'`ARCHITECTURE.md` ;
  échoue sur un chemin du registre absent, ou sur un fichier exporté d'un dossier déclaré absent du
  registre. Tests : les trois cas + cas vert.
- `new-handoff.sh <sous-spec>` : crée `docs/handoffs/<AAAAMMJJ-HHMM>-<id>.md` depuis le template,
  suffixe `-2`, `-3` si collision, affiche le chemin. Tests : chemin, collision, sous-spec absente → 1.
- `lint-docs.sh` : budgets de lignes, identifiants de règles uniques, liens Markdown internes résolus,
  bloc SES-4 identique dans template et procédure. Lancé en CI du dépôt.

## M7 — Adaptateurs et hôtes

Fichiers : `adapters/**`, `init.sh` (`--host`, `hosts`), `tests/test_hosts.sh`.

1. Vérifier dans la doc officielle de chaque hôte ce qu'il charge (AGENTS.md, CLAUDE.md, agents Kilo,
   config Aider, skills) et la syntaxe des permissions par motif de fichier dans Kilo. Noter les preuves
   (URL) dans `docs/decisions-log.md`.
2. Écrire les adaptateurs ; Kilo : Advisor et Executor avec permissions par rôle si la syntaxe le permet,
   sinon note explicite que `test-lock.sh` est le garde-fou.
3. Tests : hôte inconnu → 1 ; `claude`, `kilo`, `aider` → fichiers attendus seulement ;
   fichier hôte modifié → `.new` ; `--force` → remplacé ; `kilo.jsonc` existant jamais modifié.

## M8 — README et release candidate

Fichiers : `README.md`, `CHANGELOG.md`, `VERSION` = `1.0.0-rc.1`.

README en français : pourquoi (coût du contexte), installation, workflow avec un exemple de session
Advisor puis Executor, bloc de reprise, fast-track, tableau des hôtes vérifié en M7, protections
financières (clé par outil avec plafond, dashboard Activity, pas d'Orchestrator Kilo).

Fait quand : une personne qui ne connaît pas le dépôt installe le cadre sur un projet neuf en < 10 min.

## M9 — Pilote mesuré

1. Installer sur le projet choisi en Q2, sur une branche.
2. Advisor : `ARCHITECTURE.md` initial (registre rempli depuis le code existant), une sous-spec réelle
   et petite, ses tests verrouillés.
3. Executor : exécution dans une session neuve, à partir du bloc de reprise uniquement.
4. Relever : coût OpenRouter (Activity) par rôle, nombre d'appels d'outils, fichiers lus hors Cadre,
   violations détectées par `test-lock` et `arch-check`, nombre de sessions.
5. Ajuster les règles (seuils SES-2, taille WF-3) ; consigner dans `docs/decisions-log.md` ;
   `VERSION` = `1.0.0`.

## Risques

| Risque | Parade |
|---|---|
| Le Flash ignore les règles malgré tout | Scripts de contrôle bloquants + permissions hôte + revue |
| `ARCHITECTURE.md` diverge du code | `arch-check.sh` dans le cycle WF-7 et en PR |
| Trop de règles, contexte lourd | Budgets de lignes vérifiés, standards lus par section |
| Code de référence obsolète (Next.js, Zod évoluent) | Compilation en M2, versions notées, revue à chaque majeure |
| Coexistence avec OpenSpec dans `mbongo` | Décision Q2 avant M9 |
