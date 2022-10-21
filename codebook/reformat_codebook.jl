# reformat_codebook.jl
# reform the separate wave codebooks into a single, somewhat readable
# table.
# writes a csv and a jld object
# needed: csv versions of the existing codebooks (take the Liza-format excel
# tables and convert the first sheet to a csv file)
# this script is also a great way to check for oddities in the data (e.g.,)
# repeated rows where there shouldn't be.

using DataFrames, DataFramesMeta, CSV

import JLD2.save_object

####

# more logically re-nest the dataframe
function nestdf(x)
    x = @chain x begin
        groupby(:variable_name)
        combine(
            :repeated_question => Ref∘unique => :repeated_question,
            :question_type => Ref∘unique => :question_type,
            :survey => Ref∘unique => :survey,
            :question_english_women => Ref∘unique => :question_english_women,
            :question_english_men => Ref∘unique => :question_english_men,
            :option_code => Ref∘unique => :option_code,
            :option_english_women => Ref∘unique => :option_english_women,
            :option_english_men => Ref∘unique => :option_english_men,
        )
    end
    
    for (i,c) in enumerate(eachcol(x))
        if unique(length.(c)) == [1]
            x[!, i] = reduce(vcat, c)
        end
    end

    return x
end

# combine a vector of strings
function together(X)
    return [join(e, ", ") for e in X];
end

####

#=
note that these are the csv files generated from the "_vx" version of the 
usual codebooks.

additionally, on 2022-10-21, I made a few corrections to the data directly
in these .csv files.
=#

x1 = let
    x1 = CSV.read("w1_v8.csv", DataFrame; missingstring = "NA")
    x1 = x1[!, 1:13]
end

x2 = let
    x = CSV.read("w2_v5.csv", DataFrame; missingstring = "NA")
    names(x)
    x = x[!, 1:13]
end

x3 = let
    x = CSV.read("w3_v3.csv", DataFrame; missingstring = "NA")
    names(x)
    x = x[!, 1:13]
end

names(x1) == names(x2) == names(x3)

for xi in [x1, x2, x3]
    select!(
        xi,
        [
            "variable_name"
            "repeated_question"
            "question_type"
            "survey"
            "question_english_women"
            "question_english_men"
            "option_code"
            "option_english_women"
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

describe(x1)
describe(x2)
describe(x3)

x2[findall(length.(x2.repeated_question) .> 1), :]

x2[findall(length.(x2.question_english_men) .> 1), :]

x3[findall(length.(x3.question_english_men) .> 1), :]

x = vcat(x1, x2, x3)

names(x)

save_object("honduras_codebook.jld2", x) # before re-nesting

names(x)

x = nestdf(x)

describe(x)
names(x)

x.survey = together(x.survey);
x.repeated_question = together(x.repeated_question);
# x.question_english_men = together(x.question_english_men); # not needed
x.question_english_women = together(x.question_english_women);

x.option_code = together(x.option_code);
x.option_english_men = together(x.option_english_men);
x.option_english_women = together(x.option_english_women);

CSV.write("reformatted_codebook.csv", x; sep = ";")
