# load_css.jl

# relationship names
# kin = ["father", "mother", "sibling", "child_over12_other_house"];
# parent_child = ["father", "mother", "child_over12_other_house"];

import Pkg; Pkg.activate(".")

using HondurasTools
using HondurasTools:DataFrame
import CSV

pth = "CSS/main_data/2022-10-05/";
files = sort(readdir(pth)); # this is not super general

css, con, resp = [
    CSV.read(pth * file, DataFrame; missingstring = "NA") for file in files
];

css, con, resp = prepare_css(css, con, resp; confilter = false)

# add the sociocentric network tie values
css = handle_socio(css, con)
