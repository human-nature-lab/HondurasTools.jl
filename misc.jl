## microbiome data join

# for mb join, we need to handle the waves in the more general case
# mdat = leftjoin(mb, dat, on = [:name, :village_code]);

# import JLD2; JLD2.save_object("userfiles/mb_processed.jld2", [mdat, nf, con]);

# core = ["personal_private", "closest_friend", "free_time"];
# health = ["health_advice_get", "health_advice_give"];

# nf = let
#     # filter con to the mb village codes
#     mbcodes = sort(unique(mb.village_code));
#     rels = sort(unique(con.relationship));
    
#     # union network
#     nf = DataFrame();

#     for w in 1:3
    
#         # unionels = @subset(conns, :wave .== w); # all ties
        
#         unionels = @subset(
#             con, :wave .== w, :relationship .∈ Ref(core)
#         ); # all ties

#         # network calculations
#         nfi = egoreductions(unionels, mbcodes, :village_code);
#         nfi[!, :wave] .= w
#         append!(nf, nfi)
#     end

#     nf
# end

# import JLD2; JLD2.save_object("userfiles/mb_processed.jld2", [mdat, nf, con]);

## USE FOR SOME PURPOSES
# nf = @chain nf begin
#     select([:name, :village_code, :degree, :wave])
#     unstack([:name, :village_code], :wave, :degree)
#     rename(
#         Symbol(1) => :degree_w1,
#         Symbol(2) => :degree_w2,
#         Symbol(3) => :degree_w3
#     )
#     # dropmissing([:degree_w1, :degree_w3])
#     @transform(:Δdegree = :degree_w3 - :degree_w1)
# end

# mb_desc = describe(mb);

# dat = leftjoin(
#     resp, hh,
#     on = [
#         :building_id, :village_code, :wave,
#         :office, :municipality, :village_name
#     ]
# );