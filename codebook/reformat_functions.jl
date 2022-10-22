# reformat_functions.jl
# deps in reformat_codebook.jl

"""
        nestdf(x)

More logically re-nest the dataframe.
"""
function nestdf(x)
    x = @chain x begin
        groupby(:variable_name)
        combine(
            :repeated_question => Ref∘unique => :repeated_question,
            :question_type => Ref∘unique => :question_type,
            :wave => Ref∘unique => :wave,
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

"""
        together(X)

Combine a vector of strings and comma-separate.
"""
function together(X)
    return [join(e, ", ") for e in X];
end