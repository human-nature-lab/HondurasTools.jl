# reformat_codebook.jl

#=
reform the separate wave codebooks into a single, somewhat readable
table.

WRITE a csv and a jld object

INPUT csv versions of the existing codebooks (take the Liza-format excel
tables and convert the first sheet to a csv file)

This script is also a great way to check for oddities in the data (e.g.,
repeated rows where there shouldn't be.)

N.B.
- integer values in rows seem sorted as if they are a string (e.g.,
["1", "10", "9"]). maybe fix this someday. double check if it just matches
the order of the english options column.
=#

import Pkg; Pkg.activate(".")

using DataFrames, DataFramesMeta, CSV
import JLD2.save_object

include("reformat_functions.jl")

#=
Note that these are the csv files generated from the "_vx" version of the 
usual codebooks.

additionally, on 2022-10-21, I made a few corrections to the data directly
in these .csv files.
=#

x1 = let
    x = CSV.read("w1_v8.csv", DataFrame; missingstring = "NA")
    x = x[!, 1:13]
    x[!, :wave] .= 1
    x
end;

x2 = let
    x = CSV.read("w2_v5.csv", DataFrame; missingstring = "NA")
    x = x[!, 1:13]
    x[!, :wave] .= 2
    x[!, :repeated_question] = parse.(Int, x[!, :repeated_question])
    x
end;

x3 = let
    x = CSV.read("w3_v3.csv", DataFrame; missingstring = "NA")
    x = x[!, 1:13]
    x[!, :wave] .= 3
    x[!, :repeated_question] = parse.(Int, x[!, :repeated_question])
    x
end;

# [wave 4 when ready]

names(x1) == names(x2) == names(x3)

for xi in [x1, x2, x3]
    select!(
        xi,
        [
            "variable_name",
            "repeated_question",
            "question_type",
            "wave",
            "survey",
            "question_english_women",
            "question_english_men",
            "option_code",
            "option_english_women",
            "option_english_men"
            # "question_spanish_women"
            # "question_spanish_men"
            # "option_spanish_women"
            # "option_spanish_men"
        ]
    )
end

x1 = nestdf(x1)
x2 = nestdf(x2)
x3 = nestdf(x3)

# useful checks
# describe(x1)
# x2[findall(length.(x2.repeated_question) .> 1), :]
# x2[findall(length.(x2.question_english_men) .> 1), :]
# x3[findall(length.(x3.question_english_men) .> 1), :]

x = vcat(x1, x2, x3)

## WRITE
save_object("honduras_codebook.jld2", x) # before re-nesting

x = nestdf2(x)

# for columns with multiple values per cell, make into a comma separated
# string that can be read easily by a human.
x.survey = together(x.survey);
x.repeated_question = together(x.repeated_question);
# x.question_english_men = together(x.question_english_men); # not needed
x.question_english_women = together(x.question_english_women);

x.option_code = together(x.option_code);
x.option_english_men = together(x.option_english_men);
x.option_english_women = together(x.option_english_women);

x.wave = together(x.wave)

## WRITE
CSV.write("reformatted_codebook.csv", x; sep = ";")
