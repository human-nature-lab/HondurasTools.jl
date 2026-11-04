using HondurasTools
using Documenter

makedocs(
    sitename = "HondurasTools.jl",
    modules = [HondurasTools],
    checkdocs = :exports,
    pages = [
        "Home" => "index.md",
        "Processing and analysis" => "processing.md",
        "Codebooks and provenance" => "codebooks.md",
        "API reference" => "api.md",
        "Development" => "development.md",
    ],
)

if get(ENV, "DOCS_DEPLOY", "false") == "true"
    deploydocs(repo="github.com/human-nature-lab/HondurasTools.jl.git")
end
