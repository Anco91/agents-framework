# Architecture — <Project>

Rules: CTX-1..4, ARCH-*, LIB-3. Read this before any search. Keep it true in the same commit as the code.
Checked by `.agents-fw/scripts/arch-check.sh`.

## Stack

<!-- Language, framework, ORM, test runner, package manager, runtime versions. -->
- <item>

## Module map

<!-- One line per module: path — responsibility — main collaborators. -->
- `path/` — <responsibility>

## Declared folders

<!-- One path per line, ending with `/`. Every non-test file inside must be covered by the registry. -->
<!-- Keep only folders that hold reusable code (domain, schemas, ui, patterns, server/common...). -->

## Reuse registry

<!-- Path to a file, or to a folder ending with `/` to cover everything inside. -->
| Path | Kind | Purpose |
|---|---|---|

## Libraries

<!-- Retained libraries (LIB-1). Any addition needs a line in Decisions (LIB-3). -->
| Need | Library |
|---|---|

## Decisions

<!-- Date — decision — reason. Also: deviations from SHOULD rules, local signature, session thresholds. -->
| Date | Decision | Reason |
|---|---|---|
