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
   4. "all" => both "baseline" and "wx" were carried out -- [THIS DOESN'T MAKE SENSE? Why would the surveys overlap?]
   5. The set of questions in "baseline" varies across the waves; hence, it is denoted "baseline wx"
   6. [EXPLAIN: how connected to respondent variable indicating a new subject at wave x?]
5. Are the variables coded consistently?
   1. Not necessarily: gender is coded as "male" vs. "female" or sometimes "man" vs. "woman"?
   2. It is worth checking for consistency, the processing code here *should* resolve for gender
6. What do we do about variables that were only collected say, at W1?
   1. Case-by-case; but N.B., whether some variable is plausibly static.
7. What about people who are in a different village from W3 to W3'?
   1. (where W3' is when the microbiome data was collected)
   2. There are around 13 cases. It is currently not clear whether these were permanent moves, or not. (lives in village, works in village are both `missing` in each case)

## Summary of processing steps (fill out further)

### connections data

1. take requested connections data (W3 data as the closest to W3' MB data)
2. filter to `alter_source = 1`, `same_village = 1`
3. drop any rows with missing entries

### respondent data

1. take the requested respondent data (W3 data)
2. filter any rows with missing entries for [village_code, gender, date_of_birth, building_id]

### household data

### microbiome data
1. take the requested MB data
2. drop all rows with missing village codes
3. drop all rows s.t. `data_source != 1`
4. left-join the individual level data  to the MB data on resp. id *and* village code
   1. Depending on how we want to handle people who have a different village code for W3 and W3', we may want to adjust this.
