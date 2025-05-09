# household distances functions.jl

"""
        household_distances(bdf4)

## Description

Calculate the household distances to be matched into an edgelist-style DataFrame (below).

`bdf4` is the household data (e.g., "honduras_households_WAVE4_v2.csv").
"""
function household_distances(bdf4)
    vdst = Dict{Int, Matrix{Float64}}();
    vgr =  groupby(bdf4, :village_code);
    distvil_preall!(vdst, vgr)
    distvil!(vdst, vgr)
    return vdst, vgr
end

function distvil_preall!(vdst, vgr)
    for (k, g) in pairs(vgr)
        x = g.position;
        vdst[k.village_code] = fill(NaN, length(x), length(x));
    end
end

function distvil!(vdst, vgr)
    for (k, g) in pairs(vgr)
        x = g.position
        for i in eachindex(x), j in eachindex(x)
            if i > j # populate lower triangle only
                vdst[k.village_code][i, j] = haversine(
                    x[i], x[j], 6372.795477598
                ) # radius of earth in km  (radius quadric medium)
                # https://gscommunitycodes.usf.edu/geoscicommunitycodes/public/geophysics/Gravity/earth_shape.php
            end
        end
    end
end

"""
        distance_df(
            dst, csspath, vdst, vgr;
            a1 = :building_id_a1, a2 = :building_id_a2
        )

## Description

N.B., `a1` and `a1` are whatever two node columns you want to find distances
for (between the nodes).
"""
function distance_df(
    dst, csspath, vdst, vgr;
    a1 = :building_id_a1, a2 = :building_id_a2
)
    c = unique(csspath[!, [:village_code, a1, a2]])
    sort!(c, [:village_code, a1, a2])
    dropmissing!(c, [a1, a2])
    c[!, dst] = missings(Float64, nrow(c))

    # create vector-of-vector DataFrame to simply search
    c_ = @chain c begin
        groupby([:village_code, a1])
        combine(a2 => Ref, dst => Ref, renamecols = false)
    end

    add_dists!(c_, vdst, vgr, dst; a1, a2)
    c_ = flatten(c_, [a2, dst]); # back to usual-form DataFrame
    replace!(c_[!, dst], NaN => missing)
    return c_
end

function add_dists!(
    cred, vdst, vgr, dst;
    a1 = :building_id_a1, a2 = :building_id_a2
)

    # note that the DataFrame `cred` is in a vector-of-vector structure
    # created in `distance_df()`
    for r in eachrow(cred)
        vc = r.village_code
        # `bnames` gives the row and col. order of the buildings
        bnames = vgr[(village_code = vc,)][!, :building_id];
        i = findfirst(bnames .== r[a1])
        for (ix, e) in enumerate(r[a2])
            j = findfirst(bnames.== e)
            if !(isnothing(i) | isnothing(j))
                r[dst][ix] = if i > j # only lower triangle contains distances
                    vdst[vc][i,j]
                elseif j < i
                    vdst[vc][j,i]
                elseif j == i # same household
                    0
                else # some households do, in fact, have missing locations
                    missing
                end
            end
        end
    end
    return cred
end

"""
        hh_distances(css, hc)

Calculate and add household distances to the css data.
"""
function hh_distances(css, hc)

    # load wave 4 HH data
    hh4 = BSON.load(hc.write_path * "household_w4_" * hc.date_stamp * ".bson")[:h4];

    bdf4 = select(
        hh4,
        [:village_code, :building_id, :building_latitude, :building_longitude, :position]
    );

    dropmissing!(bdf4);

    vdst, vgr = household_distances(bdf4)

    css = select(css, [:village_code, :building_id, :building_id_a1, :building_id_a2]);

    #%% add a distances
    crd_a = distance_df(
        :hh_dist_a, css, vdst, vgr; a1 = :building_id_a1, a2 = :building_id_a2
    );

    #%% add p distances
    crd_pa1 = distance_df(
        :hh_dist_pa1, css, vdst, vgr; a1 = :building_id, a2 = :building_id_a1
    );

    crd_pa2 = distance_df(
        :hh_dist_pa2, css, vdst, vgr; a1 = :building_id, a2 = :building_id_a2
    );

    css = select(css, [:village_code, :building_id, :building_id_a1, :building_id_a2]);

    leftjoin!(css, crd_pa1, on = [:village_code, :building_id, :building_id_a1]; matchmissing = :notequal);
    leftjoin!(css, crd_pa2, on = [:village_code, :building_id, :building_id_a2]; matchmissing = :notequal);
    leftjoin!(css, crd_a, on = [:village_code, :building_id_a1, :building_id_a2]; matchmissing = :notequal);
    css.hh_dist_pa_mean = (css.hh_dist_pa1 + css.hh_dist_pa2) .* inv(2);

    BSON.bson(savepath * "household_distances" * date_stamp * ".bson", (css))
    return css
end
