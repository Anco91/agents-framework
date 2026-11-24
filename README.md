# agents-framework

Cadre portable, spec-first, pour développer avec des agents IA (Kilo Code, Claude Code, Aider, Codex,
OpenCode, Mistral Vibe, Antigravity…) sans dérive et sans brûler de tokens.

Il industrialise une façon de produire du logiciel : mêmes principes, mêmes structures, mêmes
composants dans chaque projet, pour que n'importe qui (humain ou agent) reprenne le code.

Guide pas-à-pas : [`docs/guide-utilisation.md`](docs/guide-utilisation.md).

## Pourquoi

Le coût d'un agent ne vient pas surtout du modèle, mais du **contexte** : à chaque appel d'outil,
toute la conversation est renvoyée. Une session longue, un agent qui parcourt tout le workspace, du
code recréé alors qu'il existe : la facture monte à chaque tour. Le cadre attaque ces causes :

| Problème | Réponse du cadre |
|---|---|
| Sessions longues | Une sous-spec = une session ; handoff écrit puis nouvelle session |
| Agent qui scanne tout | `ARCHITECTURE.md` : carte + registre de réutilisation ; lecture bornée |
| Code recréé | Registre obligatoire, vérifié par `arch-check.sh` |
| Modèle pas cher qui dérive | L'Advisor fixe le cadre et écrit les tests ; l'Executor ne peut pas les toucher (`test-lock.sh`) |
| Règles ignorées | Peu de règles, numérotées, citées en revue ; scripts bloquants |

## Installer

```bash
git clone https://github.com/Anco91/agents-framework.git ~/agents-framework
~/agents-framework/init.sh install /chemin/du/projet --host kilo,claude,skills
```

- Projet neuf ou existant : rien n'est écrasé. `AGENTS.md` reçoit un bloc géré entre
  `<!-- agents-fw:start -->` et `<!-- agents-fw:end -->` ; le reste du fichier ne bouge pas.
- Le cadre vit dans `.agents-fw/` (règles, standards, procédures, templates, scripts).
- Créés une seule fois, puis à toi : `ARCHITECTURE.md`, `specs/SPEC_MASTER.md`, `docs/handoffs/`.
- Hôtes (`--host`) : `claude` (`CLAUDE.md`), `kilo` (`.kilo/agents/agents-fw-advisor.md`,
  `agents-fw-executor.md`), `aider` (`.aider.conf.yml`), `skills` (`.agents/skills/agents-fw-*`).
  `init.sh hosts` liste ce que chaque hôte reçoit. Détails et preuves : [`docs/hosts.md`](docs/hosts.md).
- Projet qui a déjà des règles d'agent : `init.sh adopt /chemin/du/projet` affiche le plan ; `--apply`
  déplace les anciens fichiers dans `.agents-fw/backup/<horodatage>/` (rien n'est supprimé), puis installe.
- Hôte `claude` : exemples `settings.example.json` (`permissions.deny`) et `mcp.example.json` (Context7)
  dans `.agents-fw/adapters/claude/`, à fusionner à la main ; le cadre ne touche jamais `settings.json`
  ni `.mcp.json`. OpenSpec : `openspec/` n'est jamais modifié (guide, section « Coexister avec OpenSpec »).

Mettre à jour :

```bash
cd ~/agents-framework && git pull
./init.sh update /chemin/du/projet
```

Un fichier du cadre modifié localement est conservé ; la nouvelle version arrive à côté en `.new`.
`--force` remplace. Compatible macOS (bash 3.2) et Linux, sans dépendance.

## Le workflow

```
SPEC_MASTER.md (index)  →  change OpenSpec (proposal, deltas, design, tasks) + frame.md (Cadre, tests verrouillés)
      →  Executor  →  revue  →  ARCHITECTURE.md à jour  →  PR  →  handoff
```

1. **Advisor** (modèle fort, sessions courtes) : écrit la sous-spec et son **Cadre** — fichiers à
   créer (chemin, rôle, signatures), à modifier, liste de lecture, éléments à réutiliser,
   librairies, interdits — puis les **tests** de logique métier, qui échouent. Il les verrouille
   (`locked_tests`, `locked_at`).
2. **OpenSpec par défaut** : explorer → proposer → dérouler `tasks.md` → archiver, sans interruption
   (`openspec/changes/<id>/`, voir `docs/guide-utilisation.md`).
3. **Executor** (modèle Flash, pas cher) : nouvelle session, code uniquement dans le Cadre. Il peut
   proposer des tests (revus par l'Advisor), jamais modifier les tests verrouillés.
4. **Revue** (autre famille de modèle) : `test-lock.sh`, `arch-check.sh`, conformité au Cadre.
5. **Handoff** : `new-handoff.sh` crée `docs/handoffs/<date>-<sous-spec>.md`, et la session se
   termine par le bloc à coller dans la suivante :

```
NEXT SESSION
Role: executor
Read: AGENTS.md, ARCHITECTURE.md, docs/handoffs/20261123-1012-03-charges-period-filter.md
Sub-spec: specs/03-charges-period-filter.md (master: specs/SPEC_MASTER.md)
First action: implement periodToRange in packages/shared/src/domain/period.ts
```

Handoff obligatoire quand une sous-spec est livrée (commit + PR), et aussi après ~30 échanges,
~40 appels d'outils, 3 échecs identiques, un fichier hors Cadre ou un test qui semble faux.

**Petite correction** (≤ 3 fichiers, pas de nouveau module, pas de règle métier) : pas de spec,
commit avec le trailer `Track: fast`. Git est le journal d'audit : `git log --grep "Track: fast"`.

## Ce que le cadre impose au code

- **Architecture** : monolithe modulaire style NestJS ; schéma → service (CRUD + filtre) →
  controller ; logique métier en fonctions pures dans une lib partagée. DDD ou hexagonal seulement
  sur besoin écrit.
- **Backend** : un moteur de filtre unique (`listQuerySchema` → `toPrismaArgs`), services génériques,
  le serveur revérifie tout invariant.
- **Frontend** : Page → View → Guard → Content ; TanStack Query (`queryOptions`,
  `useSuspenseQuery`) ; pas de `useEffect` hors synchronisation externe ; état partageable dans l'URL ;
  kit de formulaire unique (react-hook-form + Zod) ; `PageLayout`, `DetailView`, `ListView`
  standard ; pas de JSX inline répété.
- **Librairies d'abord** : Zod, react-hook-form, TanStack Query, date-fns, shadcn/ui, nuqs, Prisma ;
  Pydantic, FastAPI, SQLAlchemy en Python.
- **Tests** : logique métier, schémas, filtre. Pas de tests d'UI sauf demande. Pas de seuil de
  couverture.

Code de référence prêt à copier, compilé dans un projet témoin :
[`framework/standards/reference/`](framework/standards/reference/).

## Coûts : protections conseillées

- Une clé OpenRouter par outil, avec une limite de crédit (ex. 3 $), relevée à la main.
- Suivre le tableau `Activity` d'OpenRouter, pas seulement le solde.
- Rôles par capacité, jamais par nom de modèle figé : vérifier slug et prix sur openrouter.ai.
- Complétion : modèle local (Ollama / LM Studio) ou Copilot, jamais un modèle de chat payant.
- Pas de mode Orchestrator de Kilo (déprécié, ~3× plus de tokens).

## Contenu du dépôt

| Chemin | Rôle |
|---|---|
| `framework/core.md` | Bloc injecté dans `AGENTS.md` |
| `framework/rules/` | Règles WF, ROLE, SES, TEST, CTX, GIT |
| `framework/standards/` | ARCH, BE, FE, LIB, TypeScript, Python + code de référence |
| `framework/procedures/` | Pas-à-pas : master spec, sous-spec, tests, exécution, revue, fast-track, handoff |
| `framework/templates/` | SPEC_MASTER, SUB_SPEC, ARCHITECTURE, HANDOFF, PR |
| `framework/scripts/` | `test-lock.sh`, `arch-check.sh`, `new-handoff.sh`, `lint-docs.sh`, `session-gauge.sh` |
| `adapters/` | Fichiers par hôte |
| `docs/design/` | Spec v4.1, plan, audit de la v3 |
| `docs/guide-utilisation.md` | Guide d'installation et de workflow |
| `docs/decisions-log.md` | Décisions et leurs raisons |

Tests : `bash tests/run.sh`. Lint shell : `shellcheck init.sh framework/scripts/*.sh tests/*.sh`.
Lint de la doc : `bash framework/scripts/lint-docs.sh`. La CI exécute les trois sur Linux et macOS ;
`.devin/blueprint.yaml` déclare les mêmes commandes pour Devin.
