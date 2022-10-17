# load_css.jl

# relationship names (for reference)
# kin = ["father", "mother", "sibling", "child_over12_other_house"];
# parent_child = ["father", "mother", "child_over12_other_house"];

import Pkg; Pkg.activate(".")

using HondurasTools
using HondurasTools:DataFrame
import CSV

# base path and find relevant files
pth = "CSS/main_data/2022-10-05/";
files = sort(readdir(pth)); # this is not super general

# load the liza-processed files
css, con, resp = [
    CSV.read(pth * file, DataFrame; missingstring = "NA") for file in files
];

# prepare CSS data
css, con, resp = prepare_css(css, con, resp; confilter = false)

# add the sociocentric network tie values
# (converts to a longer DataFrame)
css = handle_socio(css, con)
