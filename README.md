# HondurasTools.jl
Tools for cleaning, analyzing, and understanding the Honduras data.

DEPENDS on CSSTools.jl -- ask Eric

## Explanations & FAQ

(more explanations to be written)

1. Will this processing code work with the data that I have requested?
   1. Not clear, the code needs to be checked for flexibility (e.g., are operations "if some var present, do clean it or rely on it somehow")
2. How many datasets and files are there?
   1. There are 3 (eventually 4) waves of data, for the respondent-level, household-level, and connections data.
   2. Plus there is the microbiome data at W3', and the CSS data at W4'.
   3. Each type and wave has a separate file.
   4. One major purpose of this repository is to clean the data such that there is one data table for each type of data, including each wave. (the microbiome is currently separate). The general strategy is to take all possible variables, and leave missing where they are not collected. So, check whether some variable really ought to exist at that wave (in the reformatted codebook, which also combines across waves.)
3. How do we extract the appropriate set of isolates? (given that the edgelist doesn't have them?)
4. What is `household_id`? How do I index households?
   1. it has been deprecated in favor of `building_id`
5. Which are the microbiome villages?
   1. cf. `codebook/microbiome_villages.csv`
   2. Other villages appear in the data, because the team surveyed those from other villages who happened to be present a village while it was being surveyed.
6. How do I interpret the `survey` variable in the codebooks?
   1. For each row of the reformatted codebook, there should be an entry corresponding to each wave of the data (in which the data is present; compare to `wave`.)
   2. "baseline" => the survey was only done if a prior measurement did not exist
   3. "wx" (where x is a wave number) => implies that it was the standard survey given to everyone in that wave
   4. "all" => both "baseline" and "wx" were carried out -- [THIS DOESN'T MAKE SENSE? Why would the surveys overlap?]
   5. The set of questions in "baseline" varies across the waves; hence, it is denoted "baseline wx"
   6. [EXPLAIN: how connected to respondent variable indicating a new subject at wave x?]
   7. What do we do about variables that were only collected say, at W1?
   8. Case-by-case; but N.B., whether some variable is plausibly static.
7. What about people who are in a different village from W3 to W3'?
   1. (where W3' is when the microbiome data was collected)
   2. There are around 13 cases. It is currently not clear whether these were permanent moves, or not. (lives in village, works in village are both `missing` in each of the 13 cases)

## Codebook issues

1. `survey` variable is not clear
2. At least in the microbiome dataset, there are some variables not yet referenced.
   1. e.g., `other_resp`, `data_source`
3. Some variables are not coded consistently
   1. e.g., gender is coded as "male" vs. "female" or sometimes "man" vs. "woman"?
   2. It is worth checking for consistency (the processing code here *should* resolve for gender, but not in the underlying data)
4. (a few other things were cleaned up and fixed from the stated versions, so check the version history; e.g., variable `p1600`)

## Summary of processing steps (fill out further)

N.B. if a step is listed as "manual" it is not performed by any functions internal
to the package. It may appear in `process.jl`.

### connections data

1. take requested connections data (W3 data as the closest to W3' MB data)
2. filter to `alter_source = 1`, `same_village = 1`
3. drop any rows with missing entries

### respondent data

1. take the requested respondent data (W3 data)
2. filter any rows with missing entries for [`village_code`, `gender`, `date_of_birth`, `building_id`]
3. filter to `data_source = 1`

### household data

1. take requested HH data
2. drop all rows with missing village codes, building ids (manual)
3. prefix overlapping variables wiht `hh_`

### microbiome data

1. take the requested MB data
2. drop all rows with missing village codes (manual)
3. drop all rows s.t. `data_source != 1` (manual)
4. prefix overlapping variables with `mb_`
5. left-join the individual level data  to the MB data on resp. id *and* village code (manual)
   1. Depending on how we want to handle people who have a different village code for W3 and W3', we may want to adjust this.

- Depending on the analysis (read: most of the time), we want to remove everyone that is not in one of the 19 microbiome villages (`codebook/microbiome_villages.csv`)