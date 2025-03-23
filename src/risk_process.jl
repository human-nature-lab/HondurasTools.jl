#  process_risk.jl
# process the risk data from the microbiome dataset

statestage = Dict(
    # terminal states
    31 => 5,
    30 => 5,
    27 => 5,
    28 => 5,
    23 => 5,
    24 => 5,
    20 => 5,
    21 => 5,
    15 => 5,
    16 => 5,
    13 => 5,
    12 => 5,
    5 => 5,
    6 => 5,
    8 => 5,
    9 => 5,
    # penultimate states
    29 => 4,
    26 => 4,
    22 => 4,
    19 => 4,
    14 => 4,
    11 => 4,
    4 => 4,
    7 => 4,
    # third to last states
    25 => 3,
    18 => 3,
    10 => 3,
    3 => 3
);

statescore = Dict(
    # terminal states
    # state => (A, B) s.t. (A => gamble, B => safe)
    31 => (32, 31),
    30 => (30, 29),
    27 => (28, 27),
    28 => (26, 25),
    23 => (24, 23),
    24 => (22, 21),
    20 => (20, 19),
    21 => (18, 17),
    15 => (16, 15),
    16 => (14, 13),
    13 => (12, 11),
    12 => (10, 9),
    5 => (8, 7),
    6 => (6, 5),
    8 => (4, 3),
    9 => (2, 1),
    # penultimate states
    # state => (green, purple)
    29 => (8, 4),
    26 => (7, 4),
    22 => (6, 3),
    19 => (5, 3),
    14 => (4, 2),
    11 => (3, 2),
    4 => (2, 1),
    7 => (1, 1),
    # third to last states
    # state => purple
    25 => 4,
    18 => 3,
    10 => 2,
    3 => 1
);

function outval(outcome, tple)
    return if outcome == "Flip a coin"
        tple[1]
    elseif outcome == "Sure payment"
        tple[2]
    end
end

function process_risk(risk)

    risk = DataFrames.stack(
        risk, Not([:name, :village_code]);
        value_name = :outcome, variable_name = :choice
    );

    risk.choice_num = [Int(parse(Int, split(risk.choice[i], "_c")[2])*inv(100)) for i in 1:nrow(risk)]


    sort!(risk, [:village_code, :name])

    dropmissing!(risk, :outcome)

    riskflat = combine(
        groupby(risk, :name),
        :choice_num => Ref => :choice_nums,
        :outcome => Ref => :outcomes,
    );

    ln = length(unique(risk.name))
    risks = DataFrame(
        :name => unique(risk.name),
        :risk_score => Vector{Union{Missing, Int}}(missing, ln),
        :green_score => Vector{Union{Int, Missing}}(missing, ln),
        :purple_score => Vector{Union{Int, Missing}}(missing, ln)
    );

    sort!(riskflat, :name)
    sort!(risks, :name)
    if riskflat.name != risks.name
        error("names not aligned")
    end

    for i in 1:nrow(riskflat)
        outcomes = riskflat.outcomes[i]
        chx = riskflat.choice_nums[i]
        crnk = [get(statestage, ci, 0) for ci in chx]

        if any(crnk .> 2) # 3 is minimum scorable stage
            mx, idx = findmax(crnk)
            
            (risks.risk_score[i], risks.green_score[i], risks.purple_score[i]) = if mx == 5
                score = outval(outcomes[idx], statescore[chx[idx]])
                idxnxt = findfirst(crnk .== mx-1)
                green, purple = statescore[chx[idxnxt]]
                (score, green, purple)
            elseif mx == 4
                green, purple = statescore[chx[idx]]
                (missing, green, purple)
            elseif mx == 3
                purple = statescore[chx[idx]]
                (missing, missing, purple)
            end 
        end
    end

    return risks
end
