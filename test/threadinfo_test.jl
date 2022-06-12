using Test
using ThreadPinning

@test isnothing(threadinfo())
@test isnothing(threadinfo(; groupby = :numa))
