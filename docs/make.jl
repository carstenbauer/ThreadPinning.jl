using Documenter
using ThreadPinning
using Literate
using LinearAlgebra

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
                 "Respect Process Affinity Mask" => "examples/ex_affinity.md",
                 "MPI and MPI + Threads" => "examples/ex_mpi.md",
                 "Autochecking BLAS Thread Settings" => "examples/ex_blas.md",
                 "Measuring Core-to-Core Latency" => "examples/ex_core2core_latency.md",
             ],
             "Explanations" => [
                 "Why Pin Julia Threads?" => "explanations/why.md",
                 "Why only Linux?" => "explanations/linux.md",
                 "Julia Threads + BLAS Threads" => "explanations/blas.md",
             ],
             "References" => [
                 "API" => "refs/api.md",
                 "BLAS/LAPACK" => "refs/blaslapack.md",
                 "Latency" => "refs/latency.md",
                 "LibX" => "refs/libX.md",
                 "Likwid-Pin" => "refs/likwidpin.md",
                 "Preferences" => "refs/prefs.md",
                 "Utility" => "refs/utility.md",
             ],
         ],
         # assets = ["assets/custom.css", "assets/custom.js"]
         repo = "https://github.com/carstenbauer/ThreadPinning.jl/blob/{commit}{path}#{line}",
         format = Documenter.HTML(repolink="https://github.com/carstenbauer/ThreadPinning.jl"; collapselevel = 1))

if ci
    @info "Deploying documentation to GitHub"
    deploydocs(;
               repo = "github.com/carstenbauer/ThreadPinning.jl.git",
               devbranch = "main",
               push_preview=true,
               # target = "site",
               )
end
