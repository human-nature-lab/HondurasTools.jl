# Inside make.jl
push!(LOAD_PATH,"../src/")
using HondurasTools
using Documenter

makedocs(
         sitename = "HondurasTools.jl",
         modules  = [HondurasTools],
         pages=[
                "Home" => "index.md"
               ])
deploydocs(;
    repo="https://github.com/human-nature-lab/HondurasTools.jl",
)