# ThreadPinning.jl

[ThreadPinning.jl](https://github.com/carstenbauer/ThreadPinning.jl/) allows you to pin Julia threads to specific CPU-threads (i.e. "hardware threads" or, equivalently, "CPU processors") via functions, environment variables, or [Julia preferences](https://github.com/JuliaPackaging/Preferences.jl). Especially for applications running on HPC clusters, this is often absolutely crucial to achieve optimal performance and/or obtain reliable benchmarks (see [Why pin Julia threads?](@ref why)).

!!! note
    Be aware that Julia implements **task-based multithreading**: `M` user tasks get scheduled onto `N` Julia threads.
    While this package allows you to pin Julia threads to CPU-threads,  it is generally not
    safe to assume that a computation (started with `Threads.@spawn` or `Threads.@threads`) will run on or even stay on a certain Julia thread (see [this discourse post](https://discourse.julialang.org/t/julia-1-7-says-it-can-switch-the-thread-your-task-is-on-how-often-does-that-happen-and-how-can-it-be-disabled/75373/4?u=carstenbauer) for more information). If you want this guarantee, you can use `ThreadPinning.@spawnat` instead.

## Installation

**Note: Only Linux is supported!**

The package is registered. Hence, you can simply use
```
] add ThreadPinning
```
to add the package to your Julia environment.

### Prerequisites

To gather information about the hardware topology of the system (e.g. sockets and memory domains), ThreadPinning.jl uses [`lscpu`](https://man7.org/linux/man-pages/man1/lscpu.1.html). The latter must therefore be available (i.e. be on `PATH`), which should automatically be the case on virtually all linux systems.

In the unlikely case that `lscpu` isn't already installed on your system, here are a few ways to get it
* install `util-linux` via your system's package manager or manually from [here](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/)
* download the same as a Julia artifact: [util\_linux\_jll.jl](https://github.com/JuliaBinaryWrappers/util_linux_jll.jl)

### Autoupdate setting

By default, ThreadPinning.jl queries the system topology using `lscpu` on startup (i.e. at runtime). This is quite costly but is unfortunately necessary since you might have precompiled the package on one machine and use it from another (think e.g. login and compute nodes of a HPC cluster). However, you can tell ThreadPinning.jl to permanently skip this autoupdate at runtime and to always use the system topology that was present at compile time (i.e. when precompiling the package). This is perfectly safe if you don't use the same Julia depot on different machines, in particular if you're a "standard user" that uses Julia on a desktop computer or laptop, and can reduce the package load time significantly. To do so, simply call `ThreadPinning.Prefs.set_autoupdate(false)`.

## Terminology in This Package

* **CPU**: Chip that sits in a socket and (almost always) hosts multiple **CPU-cores**.
* **CPU-cores**: Physical processor cores of the **CPU**.
* **CPU-threads**: Hardware threads (a.k.a. "virtual cores") within the **CPU-cores**.
* **CPU ID**: Unique ID that identifies a specific **CPU-thread**. (This is somewhat inconsistent but has been chosen for brevity and backwards-compatibility reasons.)

If the system supports [SMT](https://en.wikipedia.org/wiki/Simultaneous_multithreading) ("hyperthreading"), there are more CPU-threads than CPU-cores (most commonly a factor of two more). Independent of the CPU vendor, we refer to all but the *first* CPU-threads in a core as **hyperthreads** (order is taken from `lscpu`). The latter are highlighted differently in output, see [`threadinfo()`](@ref).

## Noteworthy Alternatives

* Simply setting [`JULIA_EXCLUSIVE=1`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_EXCLUSIVE) will pin Julia threads to CPU-threads in "physical order" (i.e. as specified by `lscpu`), which might or might not include hyperthreads.
* [`pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`

## Acknowledgements

* CI infrastructure is provided by the [Paderborn Center for Parallel Computing (PC²)](https://pc2.uni-paderborn.de/)
