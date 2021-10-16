# ThreadPinning.jl

*Interactively pin Julia threads to specific cores at runtime*

## Why pin Julia threads?

Because
* [it effects performance (MFlops/s), in particular on HPC clusters with multiple NUMA domains](https://github.com/JuliaPerf/BandwidthBenchmark.jl#flopsscaling)
* [it allows you to measure hardware-performance counters in a reliable way](https://juliaperf.github.io/LIKWID.jl/stable/marker/)
* ...

## Installation

**Note: Only Linux is supported!**

The package is currently not registered. Hence, you need to
```
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

## Noteworthy Alternatives

* Setting `JULIA_EXCLUSIVE=1` will make julia use compact pinning automatically (no external tool needed!)
* [`pinthread` / `pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`
