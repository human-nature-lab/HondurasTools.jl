# HondurasTools.jl

[![Documentation](https://img.shields.io/badge/docs-main-blue.svg)](https://human-nature-lab.github.io/HondurasTools.jl/)
[![Documentation build](https://github.com/human-nature-lab/HondurasTools.jl/actions/workflows/Documentation.yaml/badge.svg?branch=main)](https://github.com/human-nature-lab/HondurasTools.jl/actions/workflows/Documentation.yaml)
[![Tests](https://github.com/human-nature-lab/HondurasTools.jl/actions/workflows/Tests.yaml/badge.svg?branch=main)](https://github.com/human-nature-lab/HondurasTools.jl/actions/workflows/Tests.yaml)

Tools for cleaning and analyzing Honduras survey and social network data in Julia.

HondurasTools combines survey waves, recodes responses, and prepares respondent, household, village, and connection tables for analysis. It also provides processed codebook lookups, longitudinal data structures, and network measures.

## Installation

Requires Julia 1.10 or later in the 1.x series. Install from GitHub with an account that has access to the repository:

```julia
using Pkg
Pkg.add(url="https://github.com/human-nature-lab/HondurasTools.jl")
```

## Quick start

The package includes machine-readable codebooks, so these lookups work without survey data or additional downloads:

```julia
using HondurasTools

cb = load_codebook()

# Question metadata and response options for RCT wave 3.
variable_info(cb, "a0200"; study="rct", wave=3)
variable_options(cb, "a0200"; study="rct", wave=3)

# Find variables by data level or type.
variables_by_level(cb, "respondent"; study="rct")
variables_by_type(cb, "outcome"; study="rct")
```

The codebooks distinguish the parent randomized controlled trial (`rct`), Intellectual Humility (`ih`), and Honduras Microbiome (`hmb`) studies. Always select the study explicitly when working outside the RCT. Wave numbers have study-specific meanings.

## Cleaning survey data

Wave-based cleaners take a vector of DataFrames and a matching vector of wave numbers. For example, this self-contained example cleans a synthetic outcome table using the bundled codebook:

```julia
using HondurasTools

cb = load_codebook()
raw = DataFrame(
    respondent_master_id=["example-a", "example-b"],
    dia_child_zinc_ka_w2=[1, 2],
    resp_target_w2=[1, 0],
)

outcomes = clean_outcomes([raw], [2]; codebook=cb, study="rct")
# Outputs include name, wave, dia_child_zinc_ka, and resp_target.
# Outcome responses 1/2 become false/true; treatment codes 1/0 become true/false.
```

| Data | Entry point |
| --- | --- |
| Respondents | `clean_respondent(tables, waves)` |
| Households | `clean_household(tables, waves)` |
| Villages | `clean_village(tables, waves)` |
| Connections | `clean_connections(tables, waves)` |
| Outcomes and treatment indicators | `clean_outcomes(tables, waves; codebook=cb, study="rct")` |
| Microbiome | `clean_microbiome(tables, administrations)` |
| Intellectual Humility and cooperation | `clean_ihr(cooperation, ih)` |

RCT cleaners accept waves 1–4. Required columns and supported optional fields vary by cleaner; codebook coverage alone does not guarantee compatibility with a particular data delivery. Wave-based cleaners may mutate their inputs. See the [processing guide](docs/src/processing.md) for input contracts, filtering defaults, missing values, and joins.

### Microbiome administrations

HMB administration IDs are **1: cohort 1 baseline**, **2: cohort 1 follow-up**, and **3: cohort 2**. Given the corresponding raw DataFrames:

```julia
mb = clean_microbiome([baseline, followup, cohort2], [1, 2, 3])
```

The result preserves repeated participants across administrations and retains cohort-specific columns. Its observation key is `(name, cohort, administration)`; duplicates within that key raise an error. The two-table shorthand `clean_microbiome(baseline, cohort2)` uses administrations `[1, 3]`.

### Generate CSV outputs

Adapt [make_data.jl](make_data.jl) to the paths and files in your local data delivery. The template processes RCT waves 1–3 and HMB baseline/cohort 2, then writes dated CSVs for each data level to `clean_data/`.

From the project directory containing your adapted script:

```sh
julia --project=. --threads=auto make_data.jl
```

The project must have HondurasTools installed. Raw participant data are not included in this repository. Review the template's sample filters and remove sections for datasets you do not have.

## Codebook sources and reproducibility

`load_codebook()` uses the bundled `variables.csv`, `options.csv`, and `derivations.csv`. To load a separate processed codebook, pass the directory containing those three files:

```julia
cb = load_codebook(path=joinpath("/path/to/codebook-repository", "codebook"))
```

The bundled CSVs match codebook release `v2026.5.1`; [provenance.json](codebook/provenance.json) records the source commit and file checksums. Record the package revision and codebook version for each analysis. Outcome recoding matches study and wave and rejects missing classifications for observed waves of known outcomes.

See [codebooks and provenance](docs/src/codebooks.md) for schemas, study coverage, categorical ordering, and external codebook maintenance.

## Analysis and documentation

Beyond cleaning, the package provides respondent/household/village histories, wave-specific tables, household distances, network construction, tie strength, constraint, and neighbor summaries.

- [Processing and analysis](docs/src/processing.md): data preparation, observation keys, and analysis helpers.
- [Codebooks and provenance](docs/src/codebooks.md): metadata queries and interpretation.
- [Documentation home](docs/src/index.md): guide navigation.
- [Development](docs/src/development.md): build the documentation site, including the generated API reference.

## Development

From a local clone:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.test()'
```

Tests use synthetic data and bundled metadata. GitHub Actions is configured to test Julia 1.10, 1.11, 1.12, and the latest stable Julia 1.x release. See [LICENSE](LICENSE) for license terms.
