#code_scratch

# levels!(
#     df.mentalhealth,
#     ["Don't know", "poor", "fair", "good", "very good", "excellent"];
#     allowmissing = true
# ) # Refused

# df.mentallyhealthy = categorical(df.mentallyhealthy, ordered = true)
# recode!(
#     df.mentallyhealthy,
#     "poor" => "No",
#     "fair" => "No",
#     "good" => "Yes",
#     "very good" => "Yes",
#     "excellent" => "Yes",
# );


# ## food

# df.foodworry = categorical(df.foodworry; ordered = true);
# levels!(df.foodworry, ["Refused", "Don't know", "No", "Yes"]);

# df.foodlack = categorical(df.foodlack; ordered = true);
# levels!(df.foodlack, ["Refused", "Don't know", "No", "Yes"]);

# df.foodskipadult = categorical(df.foodskipadult; ordered = true);
# levels!(df.foodskipadult, ["Refused", "Don't know", "No", "Yes"]);

# df.foodskipchild = categorical(df.foodskipchild; ordered = true);
# levels!(df.foodskipchild, ["Refused", "Don't know", "No", "Yes"]);

# ## pregnant

# df.pregnant = categorical(df.pregnant; ordered = true);
# levels!(df.pregnant, ["Refused", "Don't know", "No", "Yes"]);

# df.indigenous = categorical(df.indigenous)

# ## age

# df.agecat = categorical(df.agecat; ordered = true);

# ## microbiome

# mb[!, :cognitive_status] = categorical(
#     mb[!, :cognitive_status];
#     levels = ["none", "impairment", "dementia"]
# )

# mb.village_code = categorical(mb.village_code)
# mb.name = categorical(mb.name)
# mb.cognitive_status = categorical(mb.cognitive_status; ordered = true);
# mb.whereborn = categorical(mb.whereborn)
# mb.dept = categorical(mb.dept)

# ## household

# hh.building_id = categorical(hh.building_id);
# hh.hh_wealth = categorical(
#     hh.hh_wealth; ordered = true
# );

# let
#     vbl = [
#         :watersource, :cleaningagent, :toilettype, :toiletshared, :cooktype, :cookfueltype, :flooring, :windows, :walltype, :roofing
#     ];
#     for v in vbl
#         hh[!, v] = categorical(hh[!, v])
#     end
# end