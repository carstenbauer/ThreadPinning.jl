Threads.nthreads() > 1 ||
    error("Docs should be built with multiple Julia threads.")
println("--- :julia: Instantiating project")
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
Pkg.activate(@__DIR__)
Pkg.instantiate()
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
deleteat!(LOAD_PATH, 2)
println("+++ :julia: Building documentation")
include("make.jl")
