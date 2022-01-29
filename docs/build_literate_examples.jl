Threads.nthreads() ≥ 2 || error("At least two Julia threads required.")
println("--- :julia: Instantiating project")
using Pkg
Pkg.activate("..")
Pkg.instantiate()
Pkg.activate(".")
Pkg.instantiate()
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
deleteat!(LOAD_PATH, 2)
println("+++ :julia: Building Literate.jl examples")

using ThreadPinning
using Literate

const src = "https://github.com/carstenbauer/ThreadPinning.jl"

cd(@__DIR__) do
    Literate.markdown(
        "src/examples/ex_core2core_latency.jl",
        "src/examples/";
        repo_root_url="$src/blob/main/docs",
        execute=true,
    )
end