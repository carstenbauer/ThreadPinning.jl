# ThreadPinning.jl

[ThreadPinning.jl](https://github.com/carstenbauer/ThreadPinning.jl/) allows you to (interactively) pin Julia threads to specific cores at runtime. This can be important for achieving optimal performance, in particular for HPC applications running on clusters, but also for reliable benchmarking and more (see [Why pin Julia threads?](@ref why)).

!!! note
    Be aware that Julia implements task-based multithreading: `M` user tasks get scheduled onto `N` Julia threads.
    While this package allows you to pin Julia threads to cores / "hardware threads" it is generally not
    safe to assume that a computation (started with `Threads.@spawn`) will run on or even stay on a certain Julia thread (see [this discourse post](https://discourse.julialang.org/t/julia-1-7-says-it-can-switch-the-thread-your-task-is-on-how-often-does-that-happen-and-how-can-it-be-disabled/75373/4?u=carstenbauer) for more information). If you want this guarantee, you can use our [`@tspawnat`](@ref) macro.

## Installation

**Note: Only Linux is supported!**

The package is registered. Hence, you can simply use
```
] add ThreadPinning
```
to add the package to your Julia environment.

### Prerequisites

For ThreadPinning.jl to properly work, [`lscpu`](https://man7.org/linux/man-pages/man1/lscpu.1.html) must be available. This should be the case on virtually all linux systems. Only then can ThreadPinning.jl query relevant system information (sockets, NUMA nodes, hyperthreading, ...).

In the unlikely case that `lscpu` isn't already installed on your system, here are a few ways to get it
* install `util-linux` via your system's package manager or manually from [here](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/)
* download the same as a Julia artifact: [util\_linux\_jll.jl](https://github.com/JuliaBinaryWrappers/util_linux_jll.jl)

## Noteworthy Alternatives

* Setting `JULIA_EXCLUSIVE=1` will make julia use compact pinning automatically (no external tool needed!)
* [`pinthread` / `pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`

## Acknowledgements

* CI infrastructure is provided by the [Paderborn Center for Parallel Computing (PC²)](https://pc2.uni-paderborn.de/)
