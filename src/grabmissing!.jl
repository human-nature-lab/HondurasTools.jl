# grabmissing!.jl

"""
        grabmissing(cr, resp, hh, vill; rwave = 4, hhwave = 4, vwave = 3)

track missing values to add to cr

replaces with (most recent) value for that subject (could be a *later* point)
N.B. that caution is required here, because this is pretty shameless and lazy.

updates for resp, hh, and vill data of specified waves.

mutates cr, returns DataFrame with changes (decreases) in missingness
"""
function grabmissing(cr, resp, hh, vill; rwave = 4, hhwave = 4, vwave = 3)

    # variables that we do not want to update
    noupdate = [
        :building_id
        :resp_target
        :complete
        :data_source
        :other_alter_count
        :wave
        :survey_start
        :survey_end
        :surveyor
        :surveyor_gender
        :age_at_survey
        #
        :age
        :agecat
        :partnered
        :pregnant
        # css
        :village_code
        :perceiver
        :order
        :alter1
        :alter2
        :timing
        :relation
        :response
        :w4
        :kin_w4
        :w3
        :kin_w3
        :w1
        :kin_w1
        :kin_all
        :socio1
        :socio3
        :socio4
        :socio
        :free_time_dists_p
        :free_time_dists_a
        :personal_private_dists_p
        :personal_private_dists_a
        :kin_dists_p
        :kin_dists_a
        :union_dists_p
        :union_dists_a
        :any_dists_p
        :any_dists_a
        :dists_p
        :dists_a
        :free_time_dists_p_notinf
        :personal_private_dists_p_notinf
        :kin_dists_p_notinf
        :union_dists_p_notinf
        :any_dists_p_notinf
        :dists_p_notinf
        :dists_a_notinf
        :free_time_dists_p_notnan
        :personal_private_dists_p_notnan
        :kin_dists_p_notnan
    ];

    # joined full data for css with selected waves
    jdf = leveljoins(
        resp, hh, vill; rwave = rwave, hhwave = hhwave, vwave = vwave
    )
    
    ucr = unique(cr[!, [:perceiver, :building_id, :village_code]]);

    leftjoin!(
        ucr, jdf,
        on = [:perceiver => :name, :building_id, :village_code],
        matchmissing = :notequal
    );

    testref = deepcopy(ucr);

    # not sure what this is
    # this is over
    possvars = [
        :religion, :educated, :mentallyhealthy, :healthy,
        :migrateplan, :invillage, :wealth_w3, :wealth_w1, :wealth_d
    ];

    # select the set of variables to subject to updating
    intr = Symbol.(names(jdf));
    upd = @chain cr begin
        names()
        Symbol.()
        setdiff(noupdate)
        intersect(reduce(vcat, intr))
    end;

    xs = upd;

    # unitsrf = (:name, :building_id, :village_code) 
    # unitsv = (:perceiver, :building_id, :village_code)

    # this is inefficient because it will look separately
    # in hh and vill for each cr row that is missing...
    for n in eachindex(xs)
        x = xs[n];
        
        xstr = string(x)
        refdf, nm_r, nm_v = if xstr ∈ names(resp)
            resp, :name, :perceiver
        elseif xstr ∈ names(hh)
            hh, :building_id, :building_id
        elseif xstr ∈ names(vill)
            vill, :village_code, :village_code
        else 
            @warn "cannot find the variable " * string(x) * " in the reference datasets"
        end

        csel = select(ucr, [nm_v, x])
        csel = @subset csel ismissing.($x)
        csel = unique(csel)

        # for the set of individuals in `csel` (w/ missing values) on variable,
        # go find values from same respondent, if there are any
        # `refdf` will have as many or fewer persons than `csel`

        misdf = @chain refdf begin
            select(nm_r, :wave, x)
            dropmissing()
            groupby(nm_r)
            combine(x => Ref => x, :wave => Ref => :waves)
            @subset $nm_r .∈ Ref(csel[!, nm_v])
            @rtransform($x = last($x)) # use most recent value
            # could add warning or store cases where the last one is not the only unique value...
        end;

        # make it easy to find entries
        missdict = Dict(misdf[!, nm_r] .=> misdf[!, x]);

        # populate missing values in `ucr` with reference-df-pulled values
        # (again, when possible)
        for i in eachindex(ucr[!, x])
            if ismissing(ucr[i, x])
                ucr[i, x] = get(missdict, ucr[i, nm_v], missing)
            end
        end
    end

    # examine number of filled-in values
    possvars = upd
    xx = fill(NaN, length(possvars), 2)
    for (i, e) in enumerate(possvars)
        xx[i, :] = [sum(ismissing.(testref[!, e])), sum(ismissing.(ucr[!, e]))]
    end

    missΔ = DataFrame(
        :variable => possvars,
        :miss_prior => xx[:, 1], :miss_post => xx[:, 2]
    )

    return ucr, missΔ
end

export grabmissing
