# [Distributed.jl + Threads](@id distributed_threads)

ThreadPinning.jl has dedicated support for pinning Julia threads of Julia workers (Distributed.jl) in multi-processing applications, see [Querying - Distributed.jl](@ref api_distributed_querying) and [Pinning - Distributed.jl](@ref api_distributed_pinning). Note that you can use these tools irrespective of whether your parallel application is pure (i.e. each Julia workers runs a single Julia thread) or hybrid (i.e. each Julia worker runs multiple Julia threads).

## Basic example

```julia
julia> using Distributed

julia> withenv("JULIA_NUM_THREADS" => 2) do
           addprocs(4) # spawn 4 workers with 2 threads each
       end
4-element Vector{Int64}:
 2
 3
 4
 5

julia> @everywhere using ThreadPinning

julia> distributed_getcpuids()
Dict{Int64, Vector{Int64}} with 4 entries:
  5 => [246, 185]
  4 => [198, 99]
  2 => [135, 226]
  3 => [78, 184]

julia> distributed_getispinned() # none pinned yet
Dict{Int64, Vector{Bool}} with 4 entries:
  5 => [0]
  4 => [0]
  2 => [0]
  3 => [0]

julia> distributed_pinthreads(:sockets) # pin to sockets (round-robin)

julia> distributed_getispinned() # all pinned
Dict{Int64, Vector{Bool}} with 4 entries:
  5 => [1, 1]
  4 => [1, 1]
  2 => [1, 1]
  3 => [1, 1]

julia> distributed_getcpuids()
Dict{Int64, Vector{Int64}} with 4 entries:
  5 => [66, 67]
  4 => [2, 3]
  2 => [0, 1]
  3 => [64, 65]

julia> socket(1, 1:4), socket(2, 1:4) # check
([0, 1, 2, 3], [64, 65, 66, 67])

julia> distributed_pinthreads(:numa) # pin to numa domains (round-robin)

julia> distributed_getcpuids()
Dict{Int64, Vector{Int64}} with 4 entries:
  5 => [48, 49]
  4 => [32, 33]
  2 => [0, 1]
  3 => [16, 17]

julia> numa(1, 1:2), numa(2, 1:2), numa(3, 1:2), numa(4, 1:2) # check
([0, 1], [16, 17], [32, 33], [48, 49])
```