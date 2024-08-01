# ThreadPinning.jl

[ThreadPinning.jl](https://github.com/carstenbauer/ThreadPinning.jl/) allows you to pin Julia threads to specific CPU-threads (i.e. "hardware threads" or "CPU processors"). Especially for applications running on HPC clusters, this is often absolutely crucial to achieve optimal performance and/or obtain reliable benchmarks (see [Why pin Julia threads?](@ref why)).

!!! note
    Note that Julia implements **task-based multithreading**: `M` user tasks get scheduled onto `N` Julia threads.
    While this package allows you to pin Julia threads to CPU-threads,  it is generally not
    safe to assume that a computation (started with `Threads.@spawn` or `Threads.@threads`) will run on or stay on(!) a certain Julia thread (see [this discourse post](https://discourse.julialang.org/t/julia-1-7-says-it-can-switch-the-thread-your-task-is-on-how-often-does-that-happen-and-how-can-it-be-disabled/75373/4?u=carstenbauer) for more information). If you want this guarantee, you can use tools like `Threads.@threads :static` or [`ThreadPinning.@spawnat`](@ref api_stabletasks).

## Installation

The package is registered. Hence, you can simply use
```
] add ThreadPinning
```
to add the package to your Julia environment.

!!! note
    While you can install the package on all systems, **only Linux is fully supported.**
    Especially the pinning functionalities don't work on other operating systems and all basic pinning calls (e.g. [`pinthreads(:cores)`](@ref pinthreads)) will turn into no-ops. [`threadinfo()`](@ref threadinfo), and other [querying functions](@ref api_querying), should work on all systems (although the output might be limited).

### Backends

ThreadPinning.jl is based on
* [SysInfo.jl](https://github.com/carstenbauer/SysInfo.jl) for querying system information (based on [Hwloc.jl](https://github.com/JuliaParallel/Hwloc.jl) and `lscpu`) and
* [ThreadPinningCore.jl](https://github.com/carstenbauer/ThreadPinningCore.jl) for core pinning functionality (based on [libuv](https://github.com/libuv/libuv)).

## Terminology

* **CPU**: Chip that sits in a socket and (almost always) hosts multiple **CPU-cores**.
* **CPU-cores**: Physical processor cores of the **CPU**.
* **CPU-threads**: Hardware threads (a.k.a. "virtual cores") within the **CPU-cores**.
* **CPU ID**: Unique ID that identifies a specific **CPU-thread**. (This is somewhat inconsistent but has been chosen for brevity and backwards-compatibility reasons.)

If the system supports [SMT](https://en.wikipedia.org/wiki/Simultaneous_multithreading) ("hyperthreading"), there are more CPU-threads than CPU-cores (most commonly a factor of two more). Independent of the CPU vendor, we refer to all but the *first* CPU-threads in a core as **hyperthreads**. The latter are highlighted differently in output, see [`threadinfo()`](@ref).

## Noteworthy Alternatives

* Simply setting [`JULIA_EXCLUSIVE=1`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_EXCLUSIVE) will pin Julia threads to CPU-threads in "physical order" (i.e. as specified by `lscpu`), which might or might not include hyperthreads.
* [`pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`
