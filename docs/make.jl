using SymbolicMatrices
using Documenter

DocMeta.setdocmeta!(SymbolicMatrices, :DocTestSetup, :(using SymbolicMatrices); recursive=true)

makedocs(;
    modules=[SymbolicMatrices],
    authors="Alcyon Lab",
    sitename="SymbolicMatrices.jl",
    format=Documenter.HTML(;
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
