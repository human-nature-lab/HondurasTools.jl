using HondurasTools
using Documenter

makedocs(
    sitename = "HondurasTools.jl",
    modules = [HondurasTools],
    checkdocs = :exports,
    format = Documenter.HTML(
        canonical="https://human-nature-lab.github.io/HondurasTools.jl/",
        prettyurls=get(ENV, "CI", "false") == "true",
    ),
    pages = [
        "Home" => "index.md",
        "Processing and analysis" => "processing.md",
        "Wealth indices" => "wealth.md",
        "Perception and norms" => "perception.md",
        "Codebooks and provenance" => "codebooks.md",
        "API reference" => "api.md",
        "Development" => "development.md",
    ],
)
