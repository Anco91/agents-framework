# Audit — spec v3 et plan « Agent Framework » (GLM 5.3 Flash / Copilot)

Date : 2026-11-22 · Sources lues : `context-projet.md` (1559 l.), spec v3, plan v3,
dépôts `mbongo` et `vinted-tracker` (pratiques déjà en place).

Résultat : la spec v3 couvre le premier lot de demandes dans les grandes lignes,
avec 1 oubli, 4 couvertures partielles et 1 sur-correction. Le second lot
(philosophie d'ingénierie) est presque entièrement absent. Le plan a 8 défauts
qui bloquent ou faussent l'implémentation. Tout est corrigé dans la spec v4 et le plan v4.

## 1. Conformité aux demandes (lot 1 : corrections déjà demandées à l'ancien agent)

| # | Demande | État v3 | Écart | Correction v4 |
|---|---|---|---|---|
| 1a | L'agent génère le fichier de handoff au bon moment | Couvert | Déclencheur « 15-20 échanges » non mesurable par un agent | Déclencheurs observables (SES-1) |
| 1b | La consigne de nouvelle session nomme le handoff à lire (s'il y en a plusieurs) | Partiel | Un seul nom fixe `SESSION_HANDOFF.md` : plusieurs handoffs impossibles | Un fichier par sous-spec et par date, bloc final imposé (SES-2, SES-3) |
| 1c | La consigne indique la spec en cours | Couvert | — | Ajout du rôle qui reprend (advisor / executor) |
| 2a | L'Advisor écrit les tests unitaires | Couvert | — | — |
| 2b | L'Executor ne modifie pas les tests sans accord | Partiel | Règle en prose, aucune vérification | Verrou vérifiable par git + permissions hôte + protocole de demande (ROLE-3, TEST-5) |
| 2c | L'Executor peut ajouter des tests, avec revue de l'Advisor | **Absent** | Jamais mentionné | ROLE-2 : ajout dans de nouveaux fichiers, « en attente de revue », verrouillés après accord |
| 3a | L'Advisor donne le cadre : fichiers à créer, où, comment | Partiel | `PLAN_TEMPLATE` liste les fichiers ; le « comment » (signatures, éléments à réutiliser, libs) manque | Section « Cadre » de la sous-spec (ROLE-1, ARCH-6) |
| 3b | Fichier d'architecture tenu à jour à tout moment | Partiel | Seul un template existe : jamais créé dans le projet, pas de registre de réutilisation, pas de contrôle de fraîcheur | `ARCHITECTURE.md` créé à l'installation, registre, script de contrôle (CTX-2, CTX-3) |
| 4 | Ne pas tout tester ; tester le facile et le métier ; l'UI en dernier | Sur-corrigé | « 100 % logique métier » contredit « ne pas toujours tout tester » ; « tests UI interdits » va plus loin que « cadet de nos soucis » | Priorités sans seuil de couverture ; UI non testée par défaut, seulement sur demande (TEST-1, TEST-2) |
| 5 | Petites corrections sans spec, avec trace ; git suffit, YAML sans doute inutile | Couvert | « < 15 min » non mesurable par un agent | Critères objectifs + trailer de commit (WF-5, WF-6) |
| 6 | Spec master découpée en petites specs ; avis demandé | Adopté, sans avis | Manquent : statut, taille, autonomie de la sous-spec, lien branche/PR | WF-2 à WF-4, GIT-1 ; avis au §3 |

## 2. Conformité aux demandes (lot 2 : philosophie d'ingénierie)

La spec v3 ne contient que `SOUL.md` (« craftsman, FP, spec-first, lean »),
`functional.md` et `ddd-patterns.md`, sans contenu spécifié.

| Thème demandé | État v3 | Spec v4 |
|---|---|---|
| Industrialisation, standardisation, code reprenable par n'importe qui | Absent | SOUL + ARCH-5 |
| Clean archi, DDD, MVC, NestJS modulaire, SOLID, patterns, sans dogme | Contredit : séparation Domain/Application/Infrastructure et `ddd-patterns` imposés | ARCH-1 à ARCH-3 : profil par défaut léger, escalade justifiée |
| Fonction ou classe, programmation fonctionnelle, composition | Partiel (`functional.md`) | ARCH-4 |
| Compound components, pas de JSX inline répété | Absent | FE-5, FE-9 |
| Analyser avant d'implémenter, prévoir la réutilisation | Absent | ARCH-6, CTX-5 |
| Déléguer aux librairies éprouvées (react-hook-form, date-fns, shadcn) | Absent | LIB-1 à LIB-4 |
| UI atomique, formulaire / layout / vue détail standardisés | Absent | FE-6, FE-7 |
| Backend : CRUD + filtre puissant, logique dans les libs, calcul côté frontend | Absent | BE-1 à BE-5 |
| Server state (TanStack + cache), pas de state, pas de prop drilling, pas d'effets | Absent | FE-1 à FE-4 |
| Architecture frontend page → View → Guard → `children(data)` ; mieux aujourd'hui ? | Absent | FE-8 ; avis au §4 |

## 3. Avis demandé : spec master + sous-specs

Bonne idée, à garder. C'est le levier de coût principal : le contexte renvoyé à
chaque tour d'outil est ta première dépense, et une sous-spec courte borne ce contexte.

Quatre conditions pour que ça marche :

1. **Le master reste un index.** Vision, invariants, liste ordonnée des sous-specs avec statut.
   Pas de détail d'implémentation, sinon il redevient le gros fichier qu'on voulait éviter.
2. **La sous-spec est autonome.** L'Executor lit la sous-spec et `ARCHITECTURE.md`, jamais le master.
3. **Découpage vertical.** Une sous-spec = un résultat visible et livrable = une branche = une PR.
   Un découpage par couche (« tous les schémas », puis « tous les services ») ne livre rien.
4. **Détail juste à temps.** Seules les 1 ou 2 prochaines sous-specs sont rédigées en détail.
   Les autres tiennent en une ligne dans l'index. Une spec écrite trois semaines trop tôt est fausse.

Risque : les décisions transverses se perdent entre sous-specs.
Parade : elles vont dans la section « Décisions » de `ARCHITECTURE.md`, lue à chaque session.

## 4. Avis demandé : architecture frontend Guard

Ton pipeline reste valable, et `mbongo` l'applique déjà. Trois évolutions à retenir
(vérifiées dans la doc Next.js 16 et TanStack Query v5) :

1. **Le Guard devient un Server Component async** qui précharge dans un `QueryClient`
   et rend `HydrationBoundary`, sous `Suspense` et une error boundary. C'est ce que fait `mbongo`.
2. **Le Content lit avec `useSuspenseQuery`.** `data` n'est jamais `undefined` : même garantie
   que `children(data)`, sans render-prop et sans faire descendre les props.
   Un Server Component ne peut pas passer une fonction à un Client Component, donc
   `children(data)` ne survit que sur un écran 100 % serveur ; il reste valable dans ce cas.
3. **Un seul Guard générique.** `mbongo` a 9 guards presque identiques (un par domaine).
   Un Guard qui reçoit une liste de `queryOptions` les remplace tous. Les `queryOptions`
   par ressource vivent à un seul endroit, partagés par le Guard et le Content.

`use cache` (Cache Components, Next.js 16) : utile pour des données publiques ou peu
changeantes. Pas un défaut pour des données applicatives par utilisateur.

Piège vérifié pour les compound components : un Server Component ne peut pas écrire
`<Form.Title>` si `Form` vient d'un module `"use client"`. Le kit exporte donc des noms
(`FormTitle`, `FormActions`), comme shadcn.

## 5. Défauts de la spec et du plan v3 (hors demandes)

| # | Défaut | Preuve | Correction v4 |
|---|---|---|---|
| D1 | Contradiction sur le brut | Anti-objectif « ne pas archiver `context-projet.md` », mais l'arborescence, le critère 17 et la tâche 10 l'archivent | Le brut reste hors dépôt ; seul `decisions-log.md` est commité |
| D2 | Affirmation fausse sur Kilo | v3 : « pas de fichier par projet natif ». `mbongo` a `.kilo/agents/advisor.md`, `coder.md` et `kilo.jsonc` avec un modèle par agent | L'adaptateur Kilo génère les agents par rôle |
| D3 | Rôles inversés dans l'existant | Dans `mbongo`, l'advisor est un sous-agent `edit: deny` appelé par le coder : il ne peut pas écrire de tests | L'Advisor mène, avec écriture limitée aux specs, tests et `ARCHITECTURE.md` |
| D4 | L'installation échoue sur tes projets | `AGENTS.md` existe déjà dans `mbongo` et `vinted-tracker` : v3 refuse d'écraser. `SKILLS/` et le `skills/` existant de `mbongo` sont le même dossier sur un disque macOS insensible à la casse | Tout le framework dans `.agents-fw/` ; bloc géré entre marqueurs dans `AGENTS.md` |
| D5 | Le contenu des règles n'est pas spécifié | Tâche 2 : « Create SOUL.md, RULES.md… » sans contenu, confié à un Flash. C'est la dérive que le framework doit empêcher | Catalogue de règles à identifiants dans la spec ; fichiers de règles rédigés par l'Advisor |
| D6 | Tests du plan sans valeur | 6 scripts sur 7 vérifient par `grep` qu'un mot figure dans un fichier Markdown | Tests de comportement sur les scripts ; un seul lint de structure pour les documents |
| D7 | Portabilité macOS | `sha256sum` non garanti, `/bin/bash` 3.2, manifest JSON sans `jq`, confirmation interactive qui bloque un agent | Manifest texte, repli `shasum -a 256`, bash 3.2, option `--force` |
| D8 | Le plan n'applique pas sa propre règle | 11 tâches dans un seul plan, pas de sous-specs, installeur avant le contenu, aucun essai sur un vrai projet | 9 jalons livrables, contenu d'abord, pilote mesuré à la fin |

Défauts mineurs corrigés : nom du dépôt incohérent (`agents-fw` / `agent-framework`) ;
« pas de tests d'exécution » alors que `tests/*.sh` exécutent `init.sh` ; `--host all` censé
écrire « trois adaptateurs » alors que `kilo` n'écrit rien ; `init.sh update <projet>` ambigu
avec un projet nommé `update` ; fichiers supprimés en amont jamais nettoyés à la mise à jour ;
« les six hôtes lisent nativement `AGENTS.md` » jamais vérifié hôte par hôte.

## 6. Points non vérifiés (à lever pendant l'implémentation)

- Syntaxe exacte des permissions par motif de fichier dans les agents Kilo.
- Lecture native de `AGENTS.md` par chacun des six hôtes.
- Découverte automatique de `.agents/skills/` par les hôtes (exposition optionnelle des standards en skills).
