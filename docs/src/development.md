# Development and documentation

From the repository root, install the package into the documentation environment:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

The generated site is written to `docs/build/`. Local builds do not deploy. CI builds pull requests without deploying. Pushes to `main` and manual runs on `main` upload `docs/build/` and deploy it through GitHub Pages using the workflow token. No deploy key is needed. The live site follows `main` at https://human-nature-lab.github.io/HondurasTools.jl/.

Run package tests separately:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Documentation builds validate docstring references and page generation, not raw-data cleaning against a particular delivery. Review required columns, row counts, identifiers, missingness, and category levels when adapting the template. Keep raw participant data and generated analysis datasets outside version control.

Package-test CI runs on Julia 1.10, 1.11, 1.12, and the latest stable 1.x release. Synthetic regression tests cover multi-wave outcomes, study isolation, repeated HMB administrations, missing IDs, and risk-score joins; no participant data are needed.
