# Wealth indices

`wealth_indices` calculates two measures from a table containing one row per
household and wave:

- `wealth_within_d1`: MCA fitted separately in each wave. Use for relative wealth
  within that wave; these scores have different fitted weights and scales.
- `wealth_common_d1`: MCA fitted on a designated reference wave and applied to
  every row. Use for comparisons and changes across waves. Identical indicator
  profiles receive identical scores, regardless of wave.

Both measures use unweighted indicator multiple correspondence analysis (MCA).
They remain numeric scores; neither is a quintile nor a monetary wealth measure.
The default reference is wave 1. Later observations do not affect its weights.
This is a baseline-reference measure, not an MCA pooled over all waves. It assumes
the indicators retain the same meaning across waves.

## Example

```julia
using HondurasTools

# Synthetic example; replace with harmonized household indicators.
households = DataFrame(
    building_id = repeat(1:6, 2),
    wave = repeat([1, 3], inner=6),
    tv = [false,false,true,true,true,false, false,true,true,true,true,false],
    floor = ["earth","wood","wood","tile","tile","earth",
             "earth","wood","tile","tile","tile","wood"],
)
result = wealth_indices(households;
    indicators=[:tv, :floor],
    anchor=(column=:tv, low=false, high=true),
    reference_wave=1,
)
result.scores

# Score future data using the same model, without fitting again.
future = DataFrame(tv=[true], floor=["tile"])
score_wealth(result.reference_model, future)

# A separate fit when only one wave is needed:
model = fit_wealth(households[households.wave .== 1, :];
    indicators=[:tv, :floor],
    anchor=(column=:tv, low=false, high=true),
)
```

The returned object contains `scores`, `wave_models`, `reference_model`, and
`reference_wave`. Scores preserve input row order and identifiers. Additional
dimensions are named `wealth_within_d2`, `wealth_common_d2`, etc.; they are
diagnostic axes, not automatically additional measures of wealth. Set `ndims=1`
if only one nonzero dimension exists or only the first is needed.

## Replacing the R file workflow

Use `wealth/wealth-mca.jl` instead of either `wealth/wealth-mca.r` or
`wealth/wealth-mca-reference.r`. The retired R entry points stop with migration
instructions. The Julia runner calculates both measures in one call and writes:

- `wealth_index.csv`: within-wave scores with the legacy column names.
- `wealth_index_reference.csv`: reference-wave scores with the legacy column names.
- `wealth_indices.csv`: both measures with explicit within/common column names.

The first two files contain `building_id`, `wave`, `wealth_d1`, `wealth_d2`, and
`imputed`. This preserves the file contract for downstream readers. The runner
does not create diagnostic R plots. Use the score columns and fitted model
returned by `write_wealth_indices` for diagnostics in Julia.

Create a Julia configuration file that evaluates to a named tuple, adapting the
indicator names and anchor labels to the prepared input. For example:

```julia
(input_path="mca/df_mca.csv",
 imputed_path="mca/df_mca_i.csv", # omit if not using an imputed version
 output_dir="mca",
 indicators=[:tv, :floor],       # replace with the full intended indicator list
 anchor=(column=:tv, low=false, high=true),
 reference_wave=1,
 missing_policy=:category,
 unknown=:error)
```

Run `julia --project=. wealth/wealth-mca.jl /path/to/wealth_config.jl` from the
repository root. Paths in the configuration are relative to the working
directory. From Julia code, call `write_wealth_indices(input_path; ...)` directly.
An imputed dataset gets its own fits, as in the legacy R scripts; choose one
input version for longitudinal analysis. Filter on `imputed` before pivoting
legacy CSVs to avoid duplicate household/wave keys. Common scores must not be
rescaled separately by wave downstream.

## Preparing and interpreting the inputs

Supply an explicit list of harmonized categorical indicators. IDs, wave numbers,
income sufficiency, and people per room should not be in that list. The latter
two can be joined to the scores for external validation. Numeric indicator values
are interpreted as categories, not quantities. These functions do not recreate
the older R script's raw-survey recoding or imputation; clean the data first.
The existing delivered `hh_wealth_orig` is not overwritten.

The `anchor` fixes the first axis's arbitrary sign: changing its low category to
its high category must increase the score, with other indicators held constant.
Choose a substantively justified contrast present in every wave, and inspect
other category effects and validation variables before labeling the dimension
wealth. A sign convention does not make independently fitted wave scores
comparable, nor does it guarantee that the dominant axis is wealth. Category
effects are stored in `model.coefficients`, in the order given by
`model.indicators` and `model.categories`. `model.eigenvalues` and
`model.total_inertia` describe retained and total raw MCA inertia.

Missing values raise an error by default. Explicit `missing_policy=:category`
treats them as a category (as in FactoMineR's default MCA), so response missingness
can affect the axes. No implicit imputation or complete-case deletion occurs.
Categories absent from the fitted model raise an error when scoring. With
`unknown=:missing`, affected rows receive missing scores on every dimension;
the other rows are still scored. This does not override `missing_policy=:error`.
In the combined workflow, a later-wave-only category can have a within-wave score
but no common score. Harmonize or combine categories substantively before fitting
if broader coverage is needed; do not silently treat an unseen category as absence.

All rows have equal weight. Constant indicators contribute no variation but stay
in the MCA normalization; select the same indicators deliberately. Rare categories
can have strong influence. Review category frequencies and stability before using
the index for inference. Independently fitted regular and imputed datasets also
define different coordinate systems; retain one reference model when a common
scale is required. Do not standardize common scores separately within each wave.

## Validation and relation to the R scripts

The Julia implementation uses a singular-value decomposition of the standardized
complete indicator table. It follows the indicator correspondence-analysis
definition used by [FactoMineR MCA](https://rdrr.io/cran/FactoMineR/man/MCA.html).
Tests verify analytically known binary scores, full chi-square distances,
eigenvalues/covariance identities, projection, row ordering, missing categories,
and the distinction between within-wave and common scores. Near-tied eigenvalues
can make individual axes unstable even when the multi-axis geometry is stable.

### R numerical validation

The implementation was checked against **FactoMineR 2.18 in R 4.6.2** using four
reproducible synthetic datasets, each containing 80 reference-wave and 50
later-wave observations. The cases cover complete data, missing values as
categories, a constant indicator, and a rare category. All 72 reference checks
pass, including retained eigenvalues, total inertia, both independently fitted
waves, supplementary-individual projections, and standalone `predict.MCA`
projections where R returns a value. Axis signs are aligned using fitting rows
only; later-wave scores receive no separate alignment or rescaling.

| Case | Largest absolute coordinate difference |
|:--|--:|
| Complete | 2.74e-13 |
| Missing categories | 6.00e-15 |
| Constant indicator | 7.75e-14 |
| Rare category | 2.58e-14 |

FactoMineR's `MCA(ind.sup=...)` treats missing entries in supplementary rows as
categories and agrees with Julia's `missing_policy=:category` for every tested
row. Its separate `predict.MCA` method returns `NA` for new rows with raw missing
entries. That difference is recorded explicitly in the tests, rather than
silently discarding the affected rows from the comparison.

Frozen R results and their session provenance are in
`test/fixtures/wealth_factominer/`; normal Julia tests require no R installation.
To regenerate them with FactoMineR installed, run from the repository root:

```sh
Rscript test/generate_wealth_reference.R
julia --project=. --startup-file=no test/wealth.jl
```

If FactoMineR is in a separate library, set `R_LIBS` to that directory for the R
command. Validation also caught and fixed category sorting for CSV.jl's compact
string types; the reference checks read CSV inputs with the default parser.

The legacy R scripts remain available in `wealth/`. Numerical agreement with
FactoMineR on the production household inputs has not yet been checked. Before
migrating an analysis, compare identically prepared inputs, fitted coordinates
(allowing arbitrary axis signs), and held-out projections. The package does not
include those household inputs or the upstream `df_mca.csv` preparation pipeline.
