# ThreadPinning.jl

*Interactively pin Julia threads to specific cores at runtime*

## Installation

The package is currently not registered. Hence, you need to
```julia
] add https://github.com/carstenbauer/ThreadPinning.jl
```
to add the package to your Julia environment.

## Example

(Dual-socket system with 20 cores per socket, `JULIA_NUM_THREADS=8`)

```julia
ulia> using ThreadPinning

julia> getcpuids()
8-element Vector{Int64}:
 39
 25
 26
  2
 28
  3
 29
  4

julia> pinthreads(:compact)

julia> getcpuids()
8-element Vector{Int64}:
 1
 2
 3
 4
 5
 6
 7
 8

julia> pinthreads([1,3,5,7,2,4,6,8])

julia> getcpuids()
8-element Vector{Int64}:
 1
 3
 5
 7
 2
 4
 6
 8

julia> pinthreads(:scatter)

julia> getcpuids()
8-element Vector{Int64}:
  1
 21
  2
 22
  3
 23
  4
 24
```