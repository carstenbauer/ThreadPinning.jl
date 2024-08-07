using Documenter
using ThreadPinning
using Literate
using LinearAlgebra
BLAS.set_num_threads(4)

const ci = get(ENV, "CI", "") == "true"

@info "Generating Documenter.jl site"
makedocs(;
         sitename = "ThreadPinning.jl",
         authors = "Carsten Bauer",
         modules = [ThreadPinning],
         checkdocs = :exports,
         # doctest = ci,
         pages = [
             "ThreadPinning" => "index.md",
             "Examples" => [
                 "Pinning Julia Threads" => "examples/ex_pinning_julia_threads.md",
                 "Pinning Julia Tasks" => "examples/ex_pinning_tasks.md",
                 "Pinning BLAS Threads" => "examples/ex_blas.md",
                 "MPI + Threads" => "examples/ex_mpi.md",
                 "Distributed.jl + Threads" => "examples/ex_distributed.md",
                 "External Affinity Mask" => "examples/ex_affinity.md",
             ],
             "References" => [
                 "API - Pinning" => "refs/api_pinning.md",
                 "API - Querying" => "refs/api_querying.md",
                 "API - Other" => "refs/api_other.md",
                 "Internals" => "refs/internals.md",
             ],
         ],
         # assets = ["assets/custom.css", "assets/custom.js"]
         repo = "https://github.com/carstenbauer/ThreadPinning.jl/blob/{commit}{path}#{line}",
         format = Documenter.HTML(repolink="https://github.com/carstenbauer/ThreadPinning.jl")) # ; collapselevel = 1

if ci
    @info "Deploying documentation to GitHub"
    deploydocs(;
               repo = "github.com/carstenbauer/ThreadPinning.jl.git",
               devbranch = "main",
               push_preview=true,
               # target = "site",
               )
end
