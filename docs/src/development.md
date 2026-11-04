# Development and documentation

From the repository root, install the package into the documentation environment:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

The generated site is written to `docs/build/`. Local builds do not deploy. CI uses the same environment and enables deployment only on push events, using the repository's configured documentation credentials.

Run package tests separately:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Documentation builds validate docstring references and page generation, not raw-data cleaning against a particular delivery. Review required columns, row counts, identifiers, missingness, and category levels when adapting the template. Keep raw participant data and generated analysis datasets outside version control.
