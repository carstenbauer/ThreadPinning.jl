# ThreadPinning.jl

Most notably, [ThreadPinning.jl](https://github.com/carstenbauer/ThreadPinning.jl/) allows you

* to pin Julia threads to specific CPU-threads ("hardware threads") with [`pinthreads`](@ref pinthreads) and
* to obtain a visual overview of the system topology with [`threadinfo`](@ref threadinfo).

There is support for pinning Julia threads in hybrid Julia codes ([MPI + Threads](@ref mpi_threads) or [Distributed.jl + Threads](@ref distributed_threads)).

## What is this about? (10 minutes)

Check out my lightning talk that I gave as part of [JuliaCon 2023](https://juliacon.org/2023/) at MIT.

[![](https://img.youtube.com/vi/6Whc9XtlCC0/0.jpg)](https://youtu.be/6Whc9XtlCC0)

## Why pin threads?

* [It can massively impact performance (especially on HPC clusters).](https://github.com/JuliaPerf/BandwidthBenchmark.jl#flopsscaling)
* It makes performance benchmarks less noisy.
* [It is a prerequisite for hardware-performance monitoring.](https://www.youtube.com/watch?v=l2fTNfEDPC0)

## Installation

The package is registered. Hence, you can simply use
```
] add ThreadPinning
```
to add the package to your Julia environment.

!!! note
    While you can install the package on all systems, **only Linux is fully supported.**
    Especially the pinning functionality does not work on other operating systems and all basic pinning calls (e.g. [`pinthreads(:cores)`](@ref pinthreads)) will turn into no-ops. [`threadinfo()`](@ref threadinfo), and other [querying functions](@ref api_querying), should work on all systems (although the output might be limited).

## Terminology

* **CPU**: Chip that sits in a socket and (almost always) hosts multiple **CPU-cores**.
* **CPU-cores**: Physical processor cores of the **CPU**.
* **CPU-threads**: Hardware threads (a.k.a. "virtual cores") within the **CPU-cores**.
* **CPU ID**: Unique ID that identifies a specific **CPU-thread**. (This is somewhat inconsistent but has been chosen for brevity and backwards-compatibility reasons.)

If the system supports [SMT](https://en.wikipedia.org/wiki/Simultaneous_multithreading) ("hyperthreading"), there are more CPU-threads than CPU-cores (most commonly a factor of two more). Independent of the CPU vendor, we refer to all but the *first* CPU-threads in a core as **hyperthreads**. The latter are highlighted differently in output, see [`threadinfo()`](@ref).

## Backends

ThreadPinning.jl is based on
* [SysInfo.jl](https://github.com/carstenbauer/SysInfo.jl) for querying system information (based on [Hwloc.jl](https://github.com/JuliaParallel/Hwloc.jl) and `lscpu`) and
* [ThreadPinningCore.jl](https://github.com/carstenbauer/ThreadPinningCore.jl) for core pinning functionality (based on [libuv](https://github.com/libuv/libuv)).

## Noteworthy Alternatives

* Simply setting [`JULIA_EXCLUSIVE=1`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_EXCLUSIVE) will pin Julia threads to CPU-threads in "physical order" (i.e. as specified by `lscpu`), which might or might not include hyperthreads.
* [`pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`
