# load_css.jl
# example script that load and cleans the CSS data for general use.

import Pkg; Pkg.activate(".")

using HondurasTools
using HondurasTools:DataFrame
import CSV

pth = "CSS/main_data/2022-10-05/";
files = sort(readdir(pth)); # this is not super general

css, con, resp = [
    CSV.read(pth * file, DataFrame; missingstring = "NA") for file in files
];

css, con, resp = prepare_css(css, con, resp; confilter = true)
