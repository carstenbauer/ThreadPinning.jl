println("--- :julia: Instantiating project")
using Pkg
Pkg.activate("..")
Pkg.instantiate()
Pkg.activate(".")
Pkg.instantiate()
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
println("+++ :julia: Building Literate.jl examples")

using ThreadPinning
using Literate

const src = "https://github.com/carstenbauer/ThreadPinning.jl"

# cd(@__DIR__) do
#     Literate.markdown(
#         "src/examples/matrix_inv.jl", "src/examples/"; repo_root_url = "$src/blob/main/docs"
#     ) #, codefence = "```@repl 1" => "```")
# end
