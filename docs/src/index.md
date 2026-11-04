# HondurasTools.jl

[Wealth indices](wealth.md) describes wave-specific and reference-wave MCA scores.

HondurasTools cleans and combines Honduras survey deliveries and provides codebook, longitudinal, and network analysis helpers.

Start with [Processing and analysis](processing.md) for the data workflow, [Codebooks and provenance](codebooks.md) for metadata, and [API reference](api.md) for function documentation. Installation and a runnable template are described in the repository README.

The package does not distribute raw participant data. Examples requiring survey tables must be adapted to your local delivery. Cleaner input tables may be mutated; use `deepcopy` when the original tables must be retained.

[Perception and norms](perception.md) documents the optional respondent perception transformation, its question mappings, and its interpretation and missingness assumptions.
