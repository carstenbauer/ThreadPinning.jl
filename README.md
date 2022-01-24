<img align="right" src="https://github.com/carstenbauer/ThreadPinning.jl/raw/main/docs/src/assets/logo.png" width=200px>

# ThreadPinning.jl

[code-style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[code-style-url]: https://github.com/invenia/BlueStyle

<!-- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaperf.github.io/LIKWID.jl/stable/) -->
<!-- [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaperf.github.io/LIKWID.jl/dev/) -->
<!-- [![Build Status](https://github.com/JuliaPerf/LIKWID.jl/workflows/CI/badge.svg)](https://github.com/JuliaPerf/LIKWID.jl/actions) -->
[![CI@PC2](https://git.uni-paderborn.de/pc2-ci/julia/ThreadPinning-jl/badges/main/pipeline.svg?key_text=CI@PC2)](https://git.uni-paderborn.de/pc2-ci/julia/ThreadPinning-jl/-/pipelines)
[![codecov](https://codecov.io/gh/carstenbauer/ThreadPinning.jl/branch/main/graph/badge.svg?token=Ze61CbGoO5)](https://codecov.io/gh/carstenbauer/ThreadPinning.jl)
![lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
[![][code-style-img]][code-style-url]

*Interactively pin Julia threads to specific cores at runtime*

## Why pin Julia threads?

Because
* [it effects performance (MFlops/s), in particular on HPC clusters with multiple NUMA domains](https://github.com/JuliaPerf/BandwidthBenchmark.jl#flopsscaling)
* [it allows you to measure hardware-performance counters in a reliable way](https://juliaperf.github.io/LIKWID.jl/stable/marker/)
* ...

## Installation

**Note: Only Linux is supported!** (macOS doesn't support thread pinning. Windows might or might not work.)

The package is registered. Hence, you can simply use
```
] add ThreadPinning
```
to add the package to your Julia environment.

## Example

The most important functions are [`pinthreads`](#pinthreads) and [`threadinfo`](#threadinfo).

(Dual-socket system with 20 cores per socket, `julia -t 20`)

<img src="https://github.com/carstenbauer/ThreadPinning.jl/raw/main/docs/src/assets/threadinfo.png" width=900px>

To programmatically query the CPU-core IDs associated with the Julia threads, you can use [`getcpuids`](#getcpuids--getcpuid).

```julia
# julia -t 5

julia> using ThreadPinning

julia> getcpuids()
5-element Vector{Int64}:
 18
 12
 13
 14
 15

julia> pinthreads(:compact)

julia> getcpuids()
5-element Vector{Int64}:
 0
 1
 2
 3
 4
```

## Documentation

#### `pinthreads`

> `pinthreads(strategy::Symbol[; nthreads, warn, kwargs...])`
> 
> Pin the first `1:nthreads` Julia threads according to the given pinning `strategy`.
> Per default, `nthreads == Threads.nthreads()`
> 
> Allowed strategies:
> * `:compact`: pins to the first `1:nthreads` cores
> * `:scatter` or `:spread`: pins to all available sockets in an alternating / round robin fashion. To function automatically, Hwloc.jl should be loaded (i.e. `using Hwloc`). Otherwise, we the keyword arguments `nsockets` (default: `2`) and `hyperthreads` (default: `false`) can be used to indicate whether hyperthreads are available on the system (i.e. whether `Sys.CPU_THREADS == 2 * nphysicalcores`).

#### `threadinfo`

> Print information about Julia threads, e.g. on which CPU-cores they are running.
> 
> By default, the visualization will be based on `Sys.CPU_THREADS` only.
> If you also load Hwloc.jl (via `using Hwloc`) it will show more detailed information.

#### `getcpuids` / `getcpuid`

> Returns the IDs of the CPUs on which the Julia threads
> are currently running.

## Explanation

We use libc's [sched_getcpu](https://man7.org/linux/man-pages/man3/sched_getcpu.3.html) to query the CPU-core ID for a thread and libuv's [uv_thread_setaffinity](https://github.com/clibs/uv/blob/master/docs/src/threading.rst) to set the affinity of a thread.


## Noteworthy Alternatives

* Setting `JULIA_EXCLUSIVE=1` will make julia use compact pinning automatically (no external tool needed!)
* [`pinthread` / `pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`

## Acknowledgements

* CI infrastructure is provided by the [Paderborn Center for Parallel Computing (PC²)](https://pc2.uni-paderborn.de/)
