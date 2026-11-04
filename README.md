# HondurasTools.jl

Julia tools for cleaning and analyzing Honduras survey and network data. The package combines wave-specific tables, recodes survey responses, supports codebook lookups, and provides longitudinal and network utilities.

## Installation

Requires Julia 1.10 or later within the compatibility range in `Project.toml`. Install from GitHub using credentials with access to the repository:

```julia
using Pkg
Pkg.add(url="https://github.com/human-nature-lab/HondurasTools.jl")
using HondurasTools
```

For development, clone the repository and run `julia --project=.` followed by `using Pkg; Pkg.instantiate()`. Dependencies are declared in `Project.toml`; no separate GraphTools installation is required.

## Generate clean data

Raw survey data are not distributed with this package. Adapt [make_data.jl](make_data.jl) to your authorized local data delivery, specifying paths and waves in matching order. Run the adapted script from its project directory:

```sh
julia --project=. --threads=auto make_data.jl
```

The template reads RCT waves 1–3 and two microbiome cohort files, then writes dated respondent, household, village, microbiome, and connections CSVs into `clean_data/`. It is an example for a particular delivery, not a universal importer. Remove unneeded sections and check required columns before using a different request or wave. Cleaners can mutate input DataFrames.

The template keeps respondent rows labeled `"Census, survey"` and connections with raw `alter_source == 1` and `same_village == 1`. These are sample choices, not universal study inclusion rules. See the [processing guide](docs/src/processing.md) for defaults and missing-data behavior.

## Processed codebooks

`load_codebook()` loads the bundled `variables.csv`, `options.csv`, and `derivations.csv`. To use the separately maintained processed codebook, set its repository root once:

```sh
export HONDURAS_CODEBOOK="/Users/emf/Documents/Yale/yale research/honduras/codebooks honduras"
```

```julia
using HondurasTools
cb = load_codebook(path=joinpath(ENV["HONDURAS_CODEBOOK"], "codebook"))
variable_info(cb, "a0200"; study="rct", wave=3)
variable_options(cb, "a0200"; study="rct", wave=3)
variables_by_type(cb, "outcome"; study="rct")
```

The external repository currently declares version `2026.5.0`. Record the exact release/commit used for an analysis. The environment variable is a convention; HondurasTools does not read it automatically. See [codebooks and provenance](docs/src/codebooks.md) before switching between bundled and external files.

## Study scope

The processed codebook covers RCT waves 1–4, Intellectual Humility (`ih`), and Microbiome (`hmb`). HMB wave numbers describe cohort/timepoint combinations, not RCT waves. Cooperation and Cognitive Social Structures have guide material in the external repository but no codebook rows there. Codebook coverage does not imply every cleaner supports every delivery.

## Documentation and development

- [Processing and analysis](docs/src/processing.md)
- [Codebooks and provenance](docs/src/codebooks.md)
- [API reference source](docs/src/api.md)
- [Build and validation instructions](docs/src/development.md)

Run package tests with `julia --project=. -e 'using Pkg; Pkg.test()'`. Raw-data processing requires local input files and is not validated by the documentation build.
