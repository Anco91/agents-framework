# Spec master — dépôt `agents-framework`

Date : 2026-11-22 · Version : v4.1 · Statut : validée par Anco (2026-11-22)
Remplace la v3 (GLM 5.3 Flash / Copilot). Audit des écarts : `docs/design/audit-spec-v3.md`.

## 1. Intent

Anco vibe-code en spec-first avec des modèles non frontier sur OpenRouter (budget serré).
Ce qui coûte : le contexte renvoyé à chaque tour d'outil, la dérive de l'agent, le code recréé
alors qu'il existe déjà, les sessions trop longues.

Il veut un dépôt git qui **industrialise** sa façon de produire du logiciel : mêmes principes,
mêmes structures, mêmes composants dans chaque projet, pour que n'importe qui (humain ou agent)
reprenne le code. Comme une norme industrielle : un cadre commun, une signature locale possible.

Succès :
- un projet existant ou neuf prend le cadre en une commande, sans rien casser ;
- l'agent lit un cœur court, puis seulement la sous-spec, `ARCHITECTURE.md` et les fichiers listés ;
- l'Executor ne peut pas dériver : cadre, tests et fichiers lui sont imposés par l'Advisor ;
- une sous-spec livre une PR petite et relisible ; une session ≈ une sous-spec.

Échec : un gros corpus de règles que personne ne lit ; des règles dogmatiques qui produisent
plus de code qu'il n'en faut ; un setup à maintenir en six copies.

## 2. Périmètre

Objectifs :
- Catalogue de règles numérotées (§6), source unique, en anglais dans les fichiers livrés.
- Standards d'ingénierie avec code de référence : architecture, backend, frontend, librairies, TS, Python.
- Workflow master spec → sous-specs → cadre et tests Advisor → exécution → revue → handoff.
- Installeur `init.sh` : install, update, adaptateurs hôtes ; idempotent ; macOS et Linux.
- Trois scripts de contrôle : fraîcheur d'`ARCHITECTURE.md`, verrou des tests, chemin de handoff.
- Pilote mesuré sur une vraie sous-spec avant la v1.0.0.

Non-objectifs :
- Aucun appel réseau, aucune clé API, aucun slug ni prix de modèle figé.
- Pas de moteur d'orchestration : le framework est du texte et des scripts courts.
- Pas de recopie des skills personnelles d'Anco (caveman, superpowers, Matt Pocock).
- Pas de remplacement d'OpenSpec dans `mbongo` (coexistence : voir §11 Q2).

Anti-objectifs :
- Imposer DDD, hexagonal ou Clean Architecture partout.
- Viser un pourcentage de couverture de tests.
- Commiter `context-projet.md` (100 Ko, contenu triplé). Il reste hors dépôt ;
  seul `docs/decisions-log.md` (< 150 lignes) en est extrait.

## 3. Contraintes

- Hôtes : Kilo Code/Cline, Claude Code, Aider, Codex, OpenCode, Mistral Vibe, Antigravity.
  Kilo accepte des agents par projet (`.kilo/agents/*.md`, `kilo.jsonc`) : vérifié dans `mbongo`.
  La lecture native de `AGENTS.md` par chaque hôte est à vérifier en M7 (hypothèse, pas un fait).
- Budget de contexte : bloc géré de `AGENTS.md` ≤ 120 lignes ; chaque fichier de règles ou de
  standard ≤ 200 lignes ; une sous-spec ≤ 150 lignes. Vérifié par `lint-docs.sh`.
- Fichiers livrés en anglais (fiabilité des modèles) ; README, specs et templates remplis en français
  acceptés ; code toujours en anglais.
- Scripts : bash 3.2 (macOS par défaut), POSIX, `shasum -a 256` en repli de `sha256sum`,
  sans `jq`, sans prompt interactif (un agent doit pouvoir les lancer).
- Sécurité : aucun script n'écrit hors du projet cible ; refus de `/` et de `$HOME`.

## 4. Décisions de conception

| # | Décision | Raison |
|---|---|---|
| DD1 | Le framework s'installe dans `<projet>/.agents-fw/` | `AGENTS.md` existe déjà dans `mbongo` et `vinted-tracker` ; `SKILLS/` et `skills/` entrent en conflit sur un disque macOS insensible à la casse |
| DD2 | `AGENTS.md` reçoit un bloc géré entre `<!-- agents-fw:start -->` et `<!-- agents-fw:end -->` | Le contenu propre au projet hors du bloc n'est jamais touché |
| DD3 | Trois classes de fichiers : framework (`.agents-fw/`, mis à jour), projet (`ARCHITECTURE.md`, `specs/SPEC_MASTER.md`, créés une fois), hôte (`CLAUDE.md`, `.kilo/agents/*`, créés une fois puis `.new` si modifiés) | Les fichiers du projet appartiennent au projet dès leur création |
| DD4 | Manifest texte `.agents-fw/MANIFEST` : `<sha256>  <chemin>` + ligne `version` | Lisible sans `jq`, diffable |
| DD5 | L'Advisor mène, l'Executor exécute | Dans `mbongo`, l'advisor est un sous-agent en lecture seule appelé par le coder : il ne peut pas écrire de tests |
| DD6 | Verrou des tests vérifié par git (`test-lock.sh`), pas seulement par une phrase | Une règle en prose ne retient pas un modèle Flash |
| DD7 | Un fichier de handoff par session, nommé par sous-spec et horodatage | Plusieurs handoffs coexistent ; la reprise nomme le bon |
| DD8 | Pas de YAML de traçabilité : git + trailers de commit | Git versionne déjà ; `git log --grep` suffit pour l'audit |
| DD9 | Les règles du catalogue (§6) sont rédigées par l'Advisor (modèle fort), jamais par l'Executor | Le contenu des règles est l'actif ; le confier au Flash, c'est la dérive à éviter |
| DD10 | Profil d'architecture par défaut léger (modulaire type NestJS + fonctions pures), escalade documentée | Non dogmatique : la structure suit la complexité |

## 5. Structure

Dépôt `agents-framework` :

```
agents-framework/
├── README.md                    # FR : pourquoi, installer, workflow, hôtes, coûts
├── VERSION                      # semver
├── CHANGELOG.md
├── init.sh                      # install | update | --host
├── framework/                   # copié tel quel dans <projet>/.agents-fw/
│   ├── core.md                  # contenu du bloc géré d'AGENTS.md (≤ 120 l.)
│   ├── rules/
│   │   ├── workflow.md          # WF-*
│   │   ├── roles.md             # ROLE-*
│   │   ├── session.md           # SES-*
│   │   ├── testing.md           # TEST-*
│   │   ├── context.md           # CTX-*
│   │   └── git.md               # GIT-*
│   ├── standards/
│   │   ├── architecture.md      # ARCH-* + profils
│   │   ├── backend.md           # BE-* + code de référence filtre / CRUD
│   │   ├── frontend.md          # FE-* + code de référence Guard / Form / Layout
│   │   ├── libraries.md         # LIB-* + registre des librairies
│   │   ├── typescript.md
│   │   └── python.md
│   ├── procedures/              # étapes pas à pas, lues à la demande
│   │   ├── write-master-spec.md
│   │   ├── write-sub-spec.md    # dont la section Cadre
│   │   ├── write-tests.md       # Advisor
│   │   ├── execute.md           # Executor
│   │   ├── review.md
│   │   ├── fast-track.md
│   │   └── handoff.md
│   ├── templates/
│   │   ├── SPEC_MASTER.md
│   │   ├── SUB_SPEC.md
│   │   ├── ARCHITECTURE.md
│   │   ├── HANDOFF.md
│   │   └── PR.md
│   ├── examples/
│   │   ├── good-sub-spec.md
│   │   └── bad-sub-spec.md
│   └── scripts/
│       ├── arch-check.sh
│       ├── test-lock.sh
│       ├── new-handoff.sh
│       └── lint-docs.sh
├── adapters/
│   ├── claude/CLAUDE.md
│   ├── kilo/advisor.md
│   ├── kilo/executor.md
│   ├── kilo/kilo.jsonc.example
│   └── aider/.aider.conf.yml
├── docs/decisions-log.md
└── tests/
    ├── lib.sh                   # assertions, projet temporaire
    ├── test_install.sh
    ├── test_update.sh
    ├── test_hosts.sh
    ├── test_arch_check.sh
    ├── test_test_lock.sh
    ├── test_new_handoff.sh
    └── test_lint_docs.sh
```

Projet cible après `init.sh <projet>` :

```
<projet>/
├── AGENTS.md                    # bloc géré inséré ou mis à jour ; reste intact
├── ARCHITECTURE.md              # créé si absent, appartient au projet
├── specs/
│   ├── SPEC_MASTER.md           # créé si absent
│   └── 01-<slug>.md ...         # sous-specs
├── docs/handoffs/               # un fichier par handoff
└── .agents-fw/                  # framework, géré par le manifest
    └── MANIFEST
```

## 6. Catalogue de règles

Niveaux : **MUST** (bloquant en revue), **SHOULD** (écart permis s'il est écrit dans la sous-spec ou
dans `ARCHITECTURE.md` > Décisions), **MAY** (option). Les identifiants sont stables : les revues,
commits et handoffs les citent.

### 6.1 Workflow (WF)

- **WF-1 MUST** — Toute feature passe par une sous-spec validée par Anco avant le premier fichier de code.
- **WF-2 MUST** — `specs/SPEC_MASTER.md` est un index : vision, invariants, glossaire, liste ordonnée
  des sous-specs avec statut (`draft | ready | in-progress | review | done`) et dernier handoff.
  Aucun détail d'implémentation.
- **WF-3 MUST** — Une sous-spec est autonome (l'Executor ne lit jamais le master), découpée
  verticalement (un résultat observable), ≤ 150 lignes, ≤ ~8 fichiers de production touchés.
  Au-delà : découper.
- **WF-4 SHOULD** — Seules les 1 ou 2 prochaines sous-specs sont rédigées en détail ; les autres
  tiennent en une ligne dans l'index.
- **WF-5 MUST** — Fast-track sans sous-spec permis seulement si tout est vrai : ≤ 3 fichiers ;
  aucun nouveau module, fichier public, schéma, migration, route ni dépendance ; aucune règle métier
  modifiée ; pas de test verrouillé touché. Sinon : sous-spec.
- **WF-6 MUST** — Un fast-track laisse sa trace dans git : commit Conventional Commits avec trailer
  `Track: fast` et le motif. Si le correctif touche un élément du registre, `ARCHITECTURE.md` est mis à jour
  dans le même commit.
- **WF-7 MUST** — Cycle d'une sous-spec : cadre + tests (Advisor) → validation Anco → exécution
  (Executor) → revue (Advisor ou Reviewer) → `ARCHITECTURE.md` à jour → PR → statut `done` → handoff.

### 6.2 Rôles (ROLE)

- **ROLE-1 MUST** — L'Advisor (modèle fort) écrit la sous-spec et son **Cadre** : fichiers à créer
  (chemin, rôle, exports et signatures), fichiers à modifier, liste blanche de lecture, éléments du
  registre à réutiliser, librairies à utiliser, fichiers interdits. Il écrit les tests. Il n'écrit pas
  de code de production.
- **ROLE-2 MUST** — L'Executor (modèle Flash) n'écrit que du code de production dans les fichiers du
  Cadre. Il peut **ajouter** des tests, uniquement dans de nouveaux fichiers, listés dans la section
  « Tests proposés » de la sous-spec avec le statut `pending-review`. L'Advisor les accepte (ils
  rejoignent la liste verrouillée) ou les rejette.
- **ROLE-3 MUST** — L'Executor ne modifie ni ne supprime un test verrouillé. S'il pense qu'un test est
  faux, il s'arrête et écrit une demande dans « Demandes de modification de tests » (test, raison,
  proposition). Seul l'Advisor modifie, puis re-verrouille.
- **ROLE-4 MUST** — L'Executor qui a besoin d'un fichier hors Cadre s'arrête et le demande ; il ne
  l'ajoute pas lui-même.
- **ROLE-5 SHOULD** — Le Reviewer est un modèle d'une autre famille que l'Executor ; à défaut,
  l'Advisor en mode revue.
- **ROLE-6 MUST** — Les rôles sont définis par capacités (raisonnement, tool-calling fiable, coût),
  jamais par slug. Tout slug et tout prix sont vérifiés sur openrouter.ai avant configuration.

### 6.3 Sessions et handoff (SES)

- **SES-1 MUST** — Une sous-spec livrée (dernier commit poussé, PR ouverte, statut `review` ou `done`)
  déclenche toujours un handoff, même si la session est courte. La session suivante commence propre.
- **SES-2 MUST** — L'agent écrit aussi un handoff et s'arrête dès qu'un autre déclencheur observable
  est vrai : même erreur après 3 tentatives ; besoin d'un fichier hors Cadre ; demande de modification
  de test ; ~30 échanges (messages d'Anco + réponses de l'agent) dans la conversation ; ~40 appels
  d'outils ; jauge de contexte de l'hôte ≥ 60 % quand elle existe ; demande d'Anco. Les seuils se
  règlent par projet dans `ARCHITECTURE.md` > Décisions.
- **SES-3 MUST** — Le handoff est créé par `new-handoff.sh <sous-spec>` au chemin
  `docs/handoffs/<AAAAMMJJ-HHMM>-<id-sous-spec>.md`, depuis `templates/HANDOFF.md` : fait, reste,
  décisions, fichiers touchés, état des tests, blocages, prochaine action exacte.
- **SES-4 MUST** — Le dernier message de la session est ce bloc, rempli, et rien après :

  ```
  NEXT SESSION
  Role: <advisor|executor|reviewer>
  Read: AGENTS.md, ARCHITECTURE.md, <chemin exact du handoff>
  Sub-spec: <chemin exact de la sous-spec> (master: specs/SPEC_MASTER.md)
  First action: <une phrase>
  ```

- **SES-5 MUST** — L'index du master est mis à jour avec le chemin du dernier handoff de la sous-spec.
- **SES-6 MUST** — On ne compacte pas une session longue : handoff puis nouvelle session.
- **SES-7 SHOULD** — Une sous-spec tient en une session Executor ; deux au maximum, sinon la redécouper.

### 6.4 Tests (TEST)

- **TEST-1 MUST** — On teste ce qui est facile et rentable : P1 fonctions pures métier (calculs,
  règles, transformations, invariants) ; P2 schémas de validation, constructeur de filtre, mappers ;
  P3 intégration d'une frontière seulement quand elle porte un risque réel (ex. traduction filtre → requête).
- **TEST-2 MUST** — Pas de tests d'UI (rendu, DOM, JSX, styles, snapshots) sauf demande explicite d'Anco.
  Les rendre testables autrement : sortir la logique du composant dans une fonction pure.
- **TEST-3 MUST** — Pas de seuil de couverture. Critère : chaque fonction métier exportée a des tests
  qui couvrent le cas nominal, les bornes et les erreurs.
- **TEST-4 MUST** — Les tests de l'Advisor échouent avant l'exécution (preuve donnée dans la sous-spec).
- **TEST-5 MUST** — La sous-spec liste en en-tête `locked_tests` (chemins) et `locked_at` (SHA du commit
  qui les verrouille). `test-lock.sh <sous-spec>` échoue si un fichier verrouillé diffère de `locked_at`.
  Il tourne avant chaque commit de l'Executor et en revue.
- **TEST-6 SHOULD** — Pas de mock de ce qu'on possède ; une fonction pure se teste sans mock.

### 6.5 Contexte (CTX)

- **CTX-1 MUST** — Lecture au démarrage : `AGENTS.md`, `ARCHITECTURE.md`, la sous-spec (ou le handoff).
  Ensuite seulement les fichiers de la liste blanche du Cadre.
- **CTX-2 MUST** — Jamais de listage ou de recherche sur tout le workspace. Une recherche est bornée à
  un dossier cité par `ARCHITECTURE.md` ou par le Cadre.
- **CTX-3 MUST** — `ARCHITECTURE.md` est vrai à tout moment : carte des modules, **registre de
  réutilisation** (composants, hooks, fonctions pures, schémas, helpers backend : chemin + une ligne),
  librairies retenues, décisions. Tout fichier public créé, renommé ou supprimé le met à jour dans le
  même commit. `arch-check.sh` échoue si un chemin du registre n'existe plus ou si un fichier public
  nouveau (dossiers déclarés dans `ARCHITECTURE.md`) n'y figure pas.
- **CTX-4 MUST** — Avant de créer un élément, chercher dans le registre. S'il existe : le réutiliser ou
  l'étendre. S'il n'existe pas et qu'une librairie du registre LIB le couvre : la librairie.
- **CTX-5 SHOULD** — Les standards (`.agents-fw/standards/*`) sont lus à la demande, seulement la section
  utile, citée par le Cadre.

### 6.6 Git (GIT)

- **GIT-1 MUST** — Une sous-spec = une branche `feat/<id>-<slug>` = une PR. Commits Conventional Commits
  avec trailer `Spec: specs/<id>-<slug>.md`.
- **GIT-2 MUST** — Une PR décrit : sous-spec, règles citées en écart, état des tests, `arch-check` et
  `test-lock` verts.
- **GIT-3 SHOULD** — Commits petits et atomiques ; l'audit se fait par `git log --grep "Spec: "` ou
  `--grep "Track: fast"`.

### 6.7 Architecture (ARCH)

- **ARCH-1 MUST** — Profil par défaut : monolithe modulaire, un module par ressource, style NestJS
  (schema → service → controller/route), logique métier en fonctions pures dans une librairie partagée.
  MVC côté transport, rien de plus.
- **ARCH-2 SHOULD** — Escalade seulement sur besoin écrit dans `ARCHITECTURE.md` > Décisions :
  DDD tactique (entités, value objects, agrégats) quand les invariants métier sont nombreux ;
  ports/adapters seulement autour d'une intégration externe remplaçable (paiement, scraping, LLM).
- **ARCH-3 MUST** — Les principes (SOLID, Clean Code, patterns) servent la lisibilité et le changement ;
  une abstraction n'existe que si elle a au moins deux usages réels ou une frontière externe.
- **ARCH-4 MUST** — Fonctions d'abord. Une classe seulement pour un état encapsulé avec invariant ou une
  exigence de framework. Données immuables, composition plutôt qu'héritage, erreurs métier attendues en
  `Result`, exceptions pour l'inattendu.
- **ARCH-5 MUST** — Mêmes noms, mêmes emplacements, mêmes structures dans chaque projet (conventions des
  standards). Une signature locale est permise si elle est écrite dans `ARCHITECTURE.md` > Décisions.
- **ARCH-6 MUST** — Analyser avant d'implémenter : le Cadre identifie ce qui sera réutilisé ou
  réutilisable, et prévoit l'élément partagé avant le deuxième usage, pas après le troisième.

### 6.8 Backend (BE)

- **BE-1 MUST** — Un service expose le CRUD d'une ressource plus `findMany(query)` avec filtre ;
  un controller/route valide l'entrée (Zod), délègue, mappe les erreurs HTTP. Rien d'autre.
- **BE-2 MUST** — Le filtre est industrialisé dans la librairie partagée : un schéma générique
  (`eq, not, in, gte, lte, contains`, tri, pagination par curseur) et un traducteur unique
  `query → where/orderBy` par ORM. Les services l'appellent sans le réécrire.
- **BE-3 MUST** — Calculs et règles métier dans la librairie partagée, en fonctions pures, appelées par le
  frontend pour l'affichage et la simulation.
- **BE-4 MUST** — Exception de sécurité : l'autorisation, la validation et tout invariant qui protège
  l'intégrité des données sont vérifiés côté serveur, en réutilisant les mêmes fonctions pures.
  Le frontend ne fait jamais foi.
- **BE-5 SHOULD** — Un service générique `createCrudService(model, schemas)` est préféré à N services
  copiés ; un service dédié n'apparaît que pour un besoin réel hors CRUD, écrit dans la sous-spec.

### 6.9 Frontend (FE)

- **FE-1 MUST** — Donnée serveur = TanStack Query. Une fabrique `queryOptions` par ressource
  (`<resource>Queries.list(query)`, `.detail(id)`), unique source des clés de cache.
- **FE-2 MUST** — Page → View → Guard → Content. La page route ; la View compose la mise en page ;
  le Guard (Server Component async) précharge les `queryOptions` reçus dans un `QueryClient`, rend
  `HydrationBoundary` sous `Suspense` et une error boundary ; le Content lit par `useSuspenseQuery`
  (donnée garantie, jamais `undefined`). Un Guard générique, pas un par domaine.
- **FE-3 MUST** — Pas de `useEffect` pour charger, dériver ou réagir à un clic. Dériver au rendu ;
  agir dans le handler. Permis seulement pour synchroniser un système externe (listener, timer,
  intégration DOM), avec un commentaire `why`.
- **FE-4 MUST** — État local seulement pour l'UI éphémère (ouvert/fermé, brouillon) ; état partageable
  (filtres, onglet, pagination) dans l'URL ; pas de store global ; pas de prop drilling au-delà de 2
  niveaux : lire la query ou composer.
- **FE-5 MUST** — Composition : compound components pour les structures (Form, Layout, DetailView,
  List) avec exports nommés (`FormTitle`, `FormActions`…) — une notation `Form.Title` casse depuis un
  Server Component quand le module est `"use client"`.
- **FE-6 MUST** — Un seul kit formulaire (react-hook-form + `zodResolver` + schémas partagés) : titre,
  zone de champs, erreurs, actions standard (créer, modifier, supprimer, annuler) font partie de la
  structure. Un écran ne fournit que ses champs et ses handlers.
- **FE-7 MUST** — Structures standard pour `PageLayout` (titre, actions, contenu), `DetailView` (titre,
  actions, sections de lignes), `ListView` (filtres, liste, vide, pagination), `AsyncState`.
  Mêmes positions dans toute l'application.
- **FE-8 MUST** — UI atomique : primitives (`ui/`, shadcn), kit formulaire (`form/`), structures
  (`patterns/`), composants métier (`<domaine>/`). Le style vit dans les primitives, jamais dans les vues.
- **FE-9 MUST** — Pas de JSX inline répété : un bloc JSX qui apparaît deux fois devient un composant ;
  une liste se rend par un composant d'item ; une condition de rendu complexe se nomme.
- **FE-10 SHOULD** — Server Components par défaut ; `"use client"` au plus bas de l'arbre.
  `use cache` seulement pour une donnée publique ou peu changeante.

### 6.10 Librairies (LIB)

- **LIB-1 MUST** — Déléguer à une librairie éprouvée avant d'écrire un utilitaire. Registre par défaut :
  formulaires react-hook-form ; validation Zod ; donnée serveur TanStack Query ; dates date-fns ;
  primitives UI shadcn/ui ; état d'URL nuqs ; ORM Prisma (TS) ; Python : Pydantic, FastAPI, SQLAlchemy, pytest.
- **LIB-2 MUST** — Pas de `Date` natif pour calculer ou formater ; pas de validation à la main ;
  pas de gestion de formulaire à la main ; pas de primitive UI recréée.
- **LIB-3 MUST** — Ajouter une dépendance hors registre exige une ligne dans `ARCHITECTURE.md` >
  Décisions (besoin, alternatives, raison), validée par l'Advisor.
- **LIB-4 SHOULD** — Versions : majeure stable courante, épinglée par le lockfile ; doc à jour lue via
  Context7 ou la doc officielle, pas de mémoire du modèle.

## 7. Contenu des fichiers clés

- `framework/core.md` (bloc géré, ≤ 120 l.) : identité (craftsman pragmatique, industrialisation) ;
  ordre de lecture (CTX-1) ; les règles MUST les plus violées en une ligne chacune (WF-1, WF-5,
  ROLE-1 à ROLE-4, SES-1, SES-2, SES-4, TEST-1, TEST-2, CTX-2 à CTX-4, LIB-1) ; table de routage
  « pour X lis Y » vers `rules/`, `standards/`, `procedures/` ; précédence : règles du projet (hors bloc)
  > core > standards ; les skills personnelles chargées par l'hôte priment sur les procédures du framework
  si elles couvrent le même sujet.
- `standards/backend.md` : code de référence complet et court du schéma de filtre, du traducteur
  Prisma, de `createCrudService`, d'un controller de route Next.js ; équivalent FastAPI/SQLAlchemy dans
  `python.md`.
- `standards/frontend.md` : code de référence de `queryOptions`, du Guard générique, du kit `Form`
  (structure + actions standard), de `PageLayout`, `DetailView`, `ListView` ; liste des exceptions
  `useEffect` admises.
- `templates/SUB_SPEC.md` : en-tête (`id`, `status`, `locked_tests`, `locked_at`, `branch`) ; but ;
  critères d'acceptation observables ; **Cadre** (créer, modifier, lire, réutiliser, librairies,
  interdits) ; tests (verrouillés, proposés, demandes de modification) ; hors périmètre ;
  journal des handoffs.
- `templates/ARCHITECTURE.md` : dossiers déclarés (pour `arch-check`), carte des modules, registre de
  réutilisation par catégorie, librairies retenues, décisions (date, décision, raison), signature locale.
- `procedures/handoff.md` : quand (SES-1, SES-2), `new-handoff.sh`, quoi remplir, mise à jour de l'index,
  bloc SES-4.
- `adapters/kilo/advisor.md` et `executor.md` : rôles ROLE-1 et ROLE-2 avec permissions
  (Advisor : écriture limitée à `specs/`, tests, `ARCHITECTURE.md`, `docs/handoffs/` ;
  Executor : écriture refusée sur les fichiers de test). Syntaxe des permissions par motif à vérifier en M7 ;
  à défaut, `test-lock.sh` reste le garde-fou.

## 8. Comportement d'`init.sh`

```
init.sh install <projet> [--host claude,kilo,aider,skills] [--force]
init.sh update  <projet> [--host ...]
init.sh hosts                         # liste des hôtes et de ce que chacun reçoit
```

- Refuse : projet absent, `/`, `$HOME`, chemin hors répertoire existant ; refuse avant toute écriture.
- install : copie `framework/` vers `.agents-fw/` ; insère le bloc géré dans `AGENTS.md` (crée le
  fichier si absent) ; crée `ARCHITECTURE.md`, `specs/SPEC_MASTER.md`, `docs/handoffs/` s'ils manquent ;
  écrit `MANIFEST`. Second install sur un projet déjà installé = update.
- update : fichier framework inchangé depuis le manifest → remplacé ; modifié localement → conservé,
  version entrante écrite en `<fichier>.new`, avertissement ; fichier retiré en amont et inchangé →
  supprimé, modifié → conservé avec avertissement ; bloc géré réécrit, reste d'`AGENTS.md` intact ;
  fichiers projet jamais touchés.
- Manifest réécrit à la fin à partir de l'état réel des fichiers (une interruption laisse l'ancien
  manifest, et l'update suivant reprend).
- `--host` : `skills` → `.agents/skills/agents-fw-<procédure>/SKILL.md` (front-matter `name`, `description`) ;
  `claude` → `CLAUDE.md` qui pointe vers `AGENTS.md` ; `kilo` → `.kilo/agents/advisor.md`,
  `.kilo/agents/executor.md`, et affiche le fragment `kilo.jsonc` à fusionner (pas d'écriture du
  `kilo.jsonc` existant) ; `aider` → `.aider.conf.yml` qui charge `AGENTS.md` en lecture.
  Fichier hôte existant et différent → `.new`. `--force` remplace sans `.new`.
- Sortie : une ligne par fichier (`created | updated | kept (.new) | removed | unchanged`), code 0 ou 1.

## 9. Jalons (sous-specs du framework)

Le framework applique sa propre règle WF-3 : un jalon = une branche = une PR.

| # | Jalon | Résultat observable | Rédigé par |
|---|---|---|---|
| M0 | Spec master v4 + `decisions-log.md` | Spec validée par Anco | Advisor |
| M1 | `core.md` + `rules/*` | Catalogue WF, ROLE, SES, TEST, CTX, GIT en fichiers | Advisor |
| M2 | `standards/*` avec code de référence | Code de référence qui compile dans un projet témoin | Advisor, code de référence par Executor sous Cadre |
| M3 | `templates/*`, `procedures/*`, `examples/*` | Une sous-spec exemple remplie de bout en bout | Advisor |
| M4 | `init.sh install` + tests | Install sur projet vide et sur copie de `mbongo` sans perte | Executor sous Cadre |
| M5 | `init.sh update` + tests | Cas inchangé, modifié, retiré, interrompu | Executor sous Cadre |
| M6 | `arch-check`, `test-lock`, `new-handoff`, `lint-docs` + tests | Chaque script a un test qui échoue puis passe | Executor sous Cadre |
| M7 | Adaptateurs + `--host` + vérification hôte par hôte | Tableau des hôtes vérifié dans le README | Executor + vérification manuelle |
| M8 | README + v1.0.0-rc | Installation suivie par un tiers en < 10 min | Advisor |
| M9 | Pilote | Une vraie sous-spec livrée ; coût OpenRouter relevé ; règles ajustées ; v1.0.0 | Anco + Advisor + Executor |

## 10. Critères d'acceptation

1. Chaque règle du §6 figure une seule fois, avec son identifiant, dans un fichier de `framework/`.
2. `lint-docs.sh` passe : budgets de lignes (§3), identifiants uniques, liens internes résolus.
3. `init.sh install` sur une copie de `mbongo` conserve tout le contenu hors bloc de `AGENTS.md`,
   ne touche ni `skills/` ni `.kilo/`, et crée `.agents-fw/`.
4. `init.sh update` couvre les cinq cas du §8 ; testés.
5. `test-lock.sh` échoue quand un test verrouillé change et passe sinon ; testé.
6. `arch-check.sh` échoue sur un chemin du registre disparu et sur un fichier public non déclaré ; testé.
7. `new-handoff.sh` produit un chemin unique conforme à SES-3, y compris deux fois dans la même minute.
8. `templates/HANDOFF.md` et `procedures/handoff.md` contiennent le bloc SES-4 à l'identique.
9. Le Cadre de `templates/SUB_SPEC.md` contient : créer, modifier, lire, réutiliser, librairies, interdits.
10. Aucun slug de modèle, prix ou clé dans `framework/` et `adapters/`.
11. Tests du dépôt verts sur macOS (bash 3.2) et Linux.
12. Pilote M9 réalisé, coût et écarts notés dans `docs/decisions-log.md`.

## 11. Décisions d'Anco (2026-11-22)

- **Q1** — Nom du dépôt : `agents-framework`.
- **Q2** — Cible : projets neufs et projets existants (ex. `mbongo`). Le pilote M9 couvre les deux.
  Coexistence avec OpenSpec : le bloc géré ne touche pas `openspec/` ; un projet peut garder ses specs
  OpenSpec et pointer `specs/SPEC_MASTER.md` vers elles.
- **Q3** — Oui : `--host skills` expose les procédures en skills `.agents/skills/agents-fw-<nom>/SKILL.md`.
- **Q4** — Seuils SES-2 à calibrer pendant le pilote ; ajout du seuil de longueur de conversation (~30
  échanges) et du handoff obligatoire après livraison d'une sous-spec (SES-1).
