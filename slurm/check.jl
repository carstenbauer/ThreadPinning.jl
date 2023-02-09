using ThreadPinning
if length(ARGS) > 0 && ARGS[1] == "pin"
    pinthreads(:affinitymask)
end
println(getcpuids())
println("no double occupancies: ", length(unique(getcpuids())) == length(getcpuids()))
println("in order: ", issorted(getcpuids()))
