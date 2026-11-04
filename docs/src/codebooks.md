# Codebooks and provenance

## Choose a source explicitly

```julia
using HondurasTools
bundled = load_codebook()
cb = load_codebook(path=joinpath(ENV["HONDURAS_CODEBOOK"], "codebook"))
```

The path must contain `variables.csv`, `options.csv`, and `derivations.csv`; it is not the external repository root. The local processed repository is `/Users/emf/Documents/Yale/yale research/honduras/codebooks honduras`. Set `HONDURAS_CODEBOOK` to that root in your shell to use the second example. Loading a codebook does not automatically change cleaner behavior; pass it to functions that accept it, such as `clean_outcomes(...; codebook=cb)`.

The external repository declares version `2026.5.0` as inspected on 2026-11-04. Its `codebook/datapackage.json` and `codebook/schema.md` define the schema; `guides/` explains study design, identifiers, survey administration, and longitudinal changes. Consult those guides for the meaning of `survey` rather than assuming all baseline questionnaires were administered to everyone.

## Tables and lookups

| Table | Unit |
| --- | --- |
| `variables` | Study, variable, and wave |
| `options` | Study, variable, wave, and option code |
| `derivations` | Derived/outcome/treatment variable, with construction notes |

The loader returns raw DataFrames, grouped indexes, and an outcome-type lookup. Queries default to `study="rct"`; specify `"ih"` or `"hmb"` explicitly when appropriate.

```julia
variable_info(cb, "a0200"; study="rct", wave=3)
variable_options(cb, "a0200"; study="rct", wave=3)
variables_by_level(cb, "respondent"; study="rct")
variables_by_type(cb, "outcome"; study="rct")
```

Option codes reflect display order, which need not be analytical order. `make_ordered_categorical` uses English labels in option-code order; verify labels against cleaned values and select a wave to avoid repeated labels across waves. Existing cleaners may change case, wording, or coding.

## Study and wave scope

RCT covers waves 1–4. HMB uses wave 1 for cohort 1 baseline, wave 2 for cohort 1 follow-up, wave 3 for cohort 2, and wave 0 for cross-administration derived scores. These HMB values are metadata conventions and are not interchangeable with RCT waves or the cleaner's `cohort` column. IH is a separate study. The external cooperation and CSS guides are stubs without corresponding codebook rows.

## Bundled snapshot and divergence

On 2026-11-04, bundled `variables.csv` and `options.csv` were byte-identical to the external files, but `derivations.csv` differed. The bundled copy includes repaired outcome-type text, such as `knowledge and attitudes` where the external file contains `knowled ge and attitudes`. The loader normalizes whitespace runs, but does not repair spaces inserted inside words. Do not overwrite the bundled derivations without reviewing these differences.

The bundled directory also contains older reformatted and per-wave CSVs and reformatting scripts. These are historical resources, not inputs to `load_codebook()`. The bundled snapshot has no accompanying release manifest; do not assume all its files exactly match an external release.

For reproducibility, record the package commit, codebook release/commit, file checksums, study, and wave selection. Keep canonical metadata edits in the external repository and validate them there with `python scripts/validate.py`. Reconcile bundled fixes before synchronizing. Do not regenerate the external codebook casually: its extraction pipeline can overwrite manual corrections.
