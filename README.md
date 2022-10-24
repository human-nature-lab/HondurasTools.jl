# HondurasTools.jl
Tools for cleaning, analyzing the Honduras data.

## Explanations & FAQ

(more explanations to be written)

1. How do we extract the appropriate set of isolates? (given that the edgelist doesn't have them?)
2. Which are the microbiome villages?
   1. cf. `codebook/microbiome_villages.csv`
   2. Other villages appear in the data, because the team surveyed those from other villages who happened to be present a village while it was being surveyed.
3. Are the codebooks comprehensive?
   1. At least in the microbiome dataset, there are some variables not yet referenced.
4. How do I interpret the `survey` variable in the codebooks?
   1. For each row of the reformatted codebook, there should be an entry corresponding to each wave of the data (in which the data is present; compare to `wave`.)
   2. "baseline" => the survey was only done if a prior measurement did not exist
   3. "wx" (where x is a wave number) => implies that it was the standard survey given to everyone in that wave
   4. "all" => both 2 and 3 were carried out
   5. [EXPLAIN: how connected to respondent variable indicating a new subject at wave x?]
