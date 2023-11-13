# clean_ihr.jl

function dteconvert(x)
    dt, tt = split(x, "T")[1:2]
    tt = split(tt, ":")
    return DateTime(Date(dt), Time(tt[1] * ":" * tt[2]))
end

function recode_ce_b0900(x)
    return if ismissing(x)
        false
    else
        true
    end
end

newname(x, i) = Symbol(x * "_" * string(i) * "_ih")
newnames(x, rnge) = [newname(x, i) for i in rnge]

"""
        clean_ihr(cop, ihr)

Clean the Intellectual Humility Project and the cooperation experiment data.
Possibly subject to change when the data is updated.

NOT adjusted for dataselts with a limited set of requested variables.
"""
function clean_ihr(cop, ihr)

    # clean cop

    rename!(cop, :respondent_master_id => :name)

    cop.event_date = dteconvert.(cop.event_date)

    # clean ihr

    #=
    building_id_ih
    building_latitude_ih, building_longitude_ih
    village_code_ih
    village_name_ih
    municipality_ih
    office_ih
    moved_building_ih
    moved_village_ih
    =#

    rename!(
        ihr,
        :respondent_master_id => :name,
        :building_id_ih => :building_id,
        :village_code_ih => :village_code,
        :marital_name => :marital_status_ihr
    );

    ## three recollected situations

    tomissing = [
        "Refused" => missing,
        "Don't remember" => missing,
        "Dont_Know" => missing
    ];

    # when was it
    let
        xs = [:ce_a0100, :ce_a2100, :ce_a4000]
        ys = newnames("when", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # what time of day was it
    let
        xs = [:ce_a0200, :ce_a2200, :ce_a4100]
        ys = newnames("time", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # what was the weather like?
    let
        xs = [:ce_a0300, :ce_a2300, :ce_a4200]
        ys = newnames("weather", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # where were you when it happened

    let
        xs = [:ce_a0400, :ce_a2400, :ce_a4300]
        ys = newnames("where", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # What were you doing when it happened?

    let
        xs = [:ce_a0500, :ce_a2500, :ce_a4400]
        ys = newnames("doing", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # Who did you have this difference in opinion with?

    let
        xs = [:ce_a0600, :ce_a2600, :ce_a4500]
        ys = newnames("who", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # What was the difference in opinion was about?

    let
        xs = [:ce_a0700, :ce_a2700, :ce_a4600]
        ys = newnames("what", 1:3)
        for (x, y) in zip(xs, ys)
            replace!(ihr[!, x], tomissing...);
            ihr[!, x] = categorical(ihr[!, x])
            rename!(ihr, x => y)
        end
    end

    # During this conversation, I… Thought what the other person was saying was 
    # worth listening to.

    # How much did you think this?

    # leave the former as a binary variable, convert the latter into
    # a 3-valued variable

    let
        xs1 = [:ce_a0900, :ce_a2800, :ce_a4700]
        xs2 = [:ce_a1000, :ce_a2900, :ce_a4800]
        ys1 = newnames("worth_binary", 1:3)
        ys2 = newnames("worth", 1:3)
        for (x1, x2, y1, y2) in zip(xs1, xs2, ys1, ys2)
            replace!(ihr[!, x1], tomissing...);
            replace!(ihr[!, x2], tomissing...);
            ihr[findall(x -> coalesce(x == "No", false), ihr[!, x1]), x2] .= "No"
            ihr[!, x1] = passmissing(ifelse).(ihr[!, x1] .== "Yes", true, false)
            
            ihr[!, x2] = categorical(ihr[!, x2])
            rename!(ihr, x1 => y1)
            rename!(ihr, x2 => y2)
        end
    end

    # During this conversation, I thought about why the other person had a 
    # different opinion than me.

    let
        xs1 = [:ce_a1100, :ce_a3000, :ce_a4900]
        xs2 = [:ce_a1200, :ce_a3100, :ce_a5000]
        ys1 = newnames("whyother_binary", 1:3)
        ys2 = newnames("whyother", 1:3)
        for (x1, x2, y1, y2) in zip(xs1, xs2, ys1, ys2)
            replace!(ihr[!, x1], tomissing...);
            replace!(ihr[!, x2], tomissing...);
            ihr[findall(x -> coalesce(x == "No", false), ihr[!, x1]), x2] .= "No"
            ihr[!, x1] = passmissing(ifelse).(ihr[!, x1] .== "Yes", true, false)
            
            ihr[!, x2] = categorical(ihr[!, x2])
            rename!(ihr, x1 => y1)
            rename!(ihr, x2 => y2)
        end
    end

    # During this conversation, I listened carefully to what the other person
    # was saying.

    let
        xs1 = [:ce_a1300, :ce_a3200, :ce_a5100]
        xs2 = [:ce_a1400, :ce_a3300, :ce_a5200]
        ys1 = newnames("listen_binary", 1:3)
        ys2 = newnames("listen", 1:3)
        for (x1, x2, y1, y2) in zip(xs1, xs2, ys1, ys2)
            replace!(ihr[!, x1], tomissing...);
            replace!(ihr[!, x2], tomissing...);
            ihr[findall(x -> coalesce(x == "No", false), ihr[!, x1]), x2] .= "No"
            ihr[!, x1] = passmissing(ifelse).(ihr[!, x1] .== "Yes", true, false)
            
            ihr[!, x2] = categorical(ihr[!, x2])
            rename!(ihr, x1 => y1)
            rename!(ihr, x2 => y2)
        end
    end

    # During this experience, I tried to think about reasons for the difference
    # before deciding how to respond.

    let
        xs1 = [:ce_a1500, :ce_a3400, :ce_a5300]
        xs2 = [:ce_a1600, :ce_a3500, :ce_a5400]
        ys1 = newnames("reason_binary", 1:3)
        ys2 = newnames("reason", 1:3)

        for (x1, x2, y1, y2) in zip(xs1, xs2, ys1, ys2)
            replace!(ihr[!, x1], tomissing...);
            replace!(ihr[!, x2], tomissing...);
            ihr[findall(x -> coalesce(x == "No", false), ihr[!, x1]), x2] .= "No"
            ihr[!, x1] = passmissing(ifelse).(ihr[!, x1] .== "Yes", true, false)
            
            ihr[!, x2] = categorical(ihr[!, x2])
            rename!(ihr, x1 => y1)
            rename!(ihr, x2 => y2)
        end
    end

    # During this conversation, I tried to convince the other person that I was
    # correct.

    let
        xs1 = [:ce_a1700, :ce_a3600, :ce_a5500]
        xs2 = [:ce_a1800, :ce_a3700, :ce_a5600]
        ys1 = newnames("convince_binary", 1:3)
        ys2 = newnames("convince", 1:3)

        for (x1, x2, y1, y2) in zip(xs1, xs2, ys1, ys2)
            replace!(ihr[!, x1], tomissing...);
            replace!(ihr[!, x2], tomissing...);
            ihr[findall(x -> coalesce(x == "No", false), ihr[!, x1]), x2] .= "No"
            ihr[!, x1] = passmissing(ifelse).(ihr[!, x1] .== "Yes", true, false)
            
            ihr[!, x2] = categorical(ihr[!, x2])
            rename!(ihr, x1 => y1)
            rename!(ihr, x2 => y2)
        end
    end

    # During this conversation, I thought my opinion was worth more than the
    # other person’s opinion.

    let
        xs1 = [:ce_a1900, :ce_a3800, :ce_a5700]
        xs2 = [:ce_a2000, :ce_a3900, :ce_a5800]
        ys1 = newnames("worthmore_binary", 1:3)
        ys2 = newnames("worthmore", 1:3)

        for (x1, x2, y1, y2) in zip(xs1, xs2, ys1, ys2)
            replace!(ihr[!, x1], tomissing...);
            replace!(ihr[!, x2], tomissing...);
            ihr[findall(x -> coalesce(x == "No", false), ihr[!, x1]), x2] .= "No"
            ihr[!, x1] = passmissing(ifelse).(ihr[!, x1] .== "Yes", true, false)
            
            ihr[!, x2] = categorical(ihr[!, x2])
            rename!(ihr, x1 => y1)
            rename!(ihr, x2 => y2)
        end
    end

    #=
    Imagine the following situation: Today you unexpectedly received 1,000 
    Lempiras. How much of this amount would you donate to a good cause?
    =#

    rename!(ihr, :ce_b0100 => :donate_ih);
    replace!(ihr[!, :donate_ih], "Dont_Know" => missing);
    ihr[!, :donate_ih] = passmissing(parse).(Int, ihr[!, :donate_ih]);

    # What do you do most of the time?

    ihr[!, :do] = categorical(ihr[!, :ce_b0200]);

    #= 
    Was there any other activity that you engaged in to earn income or contribute 
    to the economic situation of your household even if you didn't receive payment? 
    DO NOT READ ANSWERS
    =#
    
    ce_b0900_dict = Dict(
        :ce_b0900_a => :work_noexp_ih, # there should be an answer Yes for `b`-`i`
        :ce_b0900_b => :farm_noexp_ih,
        :ce_b0900_c => :products_food_noexp_ih,
        :ce_b0900_d => :constr_repair_clean_noexp_ih,
        :ce_b0900_e => :tourist_noexp_ih,
        :ce_b0900_f => :transport_noexp_ih,
        :ce_b0900_g => :manuf_noexp_ih,
        :ce_b0900_h => :kin_noexp_ih,
        :ce_b0900_i => :other_noexp_ih
    )

    ce_b0900 = collect(keys(sort(ce_b0900_dict)));

    for x in ce_b0900[2:end]
        ihr[!, x] = recode_ce_b0900.(ihr[!, x])
    end

    ihr[!, ce_b0900[1]] = .!recode_ce_b0900.(ihr[!, ce_b0900[1]])

    for e in ce_b0900_dict; rename!(ihr, e) end

    let
        dts = Vector{DateTime}(undef, nrow(ihr)) |> allowmissing
        for (i, x) in enumerate(ihr[!, :created_at])
            dts[i] = if !ismissing(x)
                a, b = split(x, " ")
                DateTime(Date(a), Time(b))
            else
                missing
            end
        end
        ihr[!, :created_at] = dts
        rename!(ihr, :created_at => :survey_start_ih)
    end

    ihr.complete = Bool.(ihr.complete)

    notvariables = [
        :ce_a0010
        :ce_b9990
        :ce_b9991
        :ce_a9990
        :ce_a9991
        :ce_a9992
        :ce_a9993
        :ce_a9994
        :ce_a9995
        :ce_a9996
        :ce_a9997
        :ce_a9998
        :ce_a9999
        :ce_b9990
        :ce_b9991
    ];

    select!(ihr, Not(notvariables))


    # duplicates of main survey
    dupe_variables = [
        :village_name_ih, :municipality_ih, :office_ih,
        :building_latitude_ih, :building_longitude_ih,
        :gender, :date_of_birth,
        :completed_at, :surveyor_id
    ];

    select!(ihr, Not(dupe_variables));

    return cop, ihr
end

# categorical coding

function code_ihr!(ihr)
    ccvars = [
        "when", "time", "weather", "where", "doing", "who", "what",
        "worth", "whyother",
        "listen", "reason",
        "convince", "worthmore"
    ]; # don't include binary versions # these should also be ordered!
    cat_vars = [
        :village_code, :player, :name, :form_type,
        reduce(vcat, [newnames(u, 1:3) for u in ccvars])...,
        :do,
        :work_noexp_ih, :farm_noexp_ih, :products_food_noexp_ih, 
        :constr_repair_clean_noexp_ih, :tourist_noexp_ih, :transport_noexp_ih, 
        :manuf_noexp_ih, :kin_noexp_ih, :other_noexp_ih
    ];

    for v in cat_vars
        ihr[!, v] = categorical(ihr[!, v]);
    end
end

function code_cop!(cop)
    for v in [:village_code, :player, :name, :group]
        cop[!, v] = categorical(cop[!, v]);
    end
end
