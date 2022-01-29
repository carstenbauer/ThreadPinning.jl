# push!(LOAD_PATH,"../src/")
using Documenter
using DocThemePC2
using ThreadPinning
using Literate
using LinearAlgebra
# using MKL # optional
# BLAS.set_num_threads(1)

const src = "https://github.com/carstenbauer/ThreadPinning.jl"
const ci = get(ENV, "CI", "") == "true"

# @info "Building Literate.jl documentation"
# cd(@__DIR__) do
#     Literate.markdown(
#         "src/examples/matrix_inv.jl", "src/examples/"; repo_root_url = "$src/blob/main/docs"
#     ) #, codefence = "```@repl 1" => "```")
#     Literate.markdown(
#         "src/examples/matrix_inv_distributed.jl",
#         "src/examples/";
#         repo_root_url = "$src/blob/main/docs"
#     ) #, codefence = "```@repl 1" => "```")
#     Literate.markdown(
#         "src/examples/matrix_inv_mpi.jl",
#         "src/examples/";
#         repo_root_url = "$src/blob/main/docs"
#     ) #, codefence = "```@repl 1" => "```")
# end

@info "Preparing DocThemePC2"
DocThemePC2.install(@__DIR__)

@info "Generating Documenter.jl site"
makedocs(;
    sitename = "ThreadPinning.jl",
    authors = "Carsten Bauer",
    modules = [ThreadPinning],
    checkdocs = :exports,
    # doctest = ci,
    pages = [
        "ThreadPinning" => "index.md",
        # "Examples" => [
        #     "Matrix Inversion" => "examples/matrix_inv.md",
        #     "Matrix Inversion (Distributed)" => "examples/matrix_inv_distributed.md",
        #     "Matrix Inversion (MPI)" => "examples/matrix_inv_mpi.md",
        # ],
        # "Explanations" => ["Submatrix Method" => "explanations/smmethod.md"],
        # "References" => [
        #     "API" => "refs/api.md",
        #     "Launch Configurations" => "refs/lc.md",
        #     "Core" => "refs/submatrix_core.md",
        #     "IO" => "refs/io.md",
        #     "Utility" => "refs/utility.md",
        # ],
    ],
    # assets = ["assets/custom.css", "assets/custom.js"]
    # repo = "https://github.com/carstenbauer/ThreadPinning.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(; collapselevel = 1)#, assets = ["assets/favicon.ico"])
)

if ci
    @info "Deploying documentation to GitHub"
    deploydocs(;
        repo = "github.com/carstenbauer/ThreadPinning.jl",
        push_preview = true
        # target = "site",
    )
end