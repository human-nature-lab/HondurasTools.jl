# Julia entry point replacing wealth-mca.r and wealth-mca-reference.r.
# Run from the repository root:
# julia --project=. wealth/wealth-mca.jl /path/to/wealth_config.jl
# The config file must evaluate to a NamedTuple of write_wealth_indices keywords
# plus input_path; see docs/src/wealth.md for an example.
using HondurasTools

function main(args)
    length(args) == 1 || error("Usage: julia --project=. wealth/wealth-mca.jl CONFIG.jl")
    config = include(abspath(only(args)))
    config isa NamedTuple || error("Config must evaluate to a NamedTuple")
    hasproperty(config, :input_path) || error("Config must specify input_path")
    options = Base.structdiff(config, NamedTuple{(:input_path,)}((config.input_path,)))
    write_wealth_indices(config.input_path; options...)
    println("Julia wealth indices written to ", get(config, :output_dir, dirname(config.input_path)))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
