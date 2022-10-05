# Pinning Julia Threads

Generally speaking, the most important functions are [`pinthreads`](@ref) and [`threadinfo`](@ref).

## Typical usage

Below, we consider a dual-socket system where each CPU has 20 hardware threads and start julia with 20 threads, i.e. `julia -t 20`.

### `color=true` (default)

![threadinfo_noht.png](threadinfo_noht.png)

### `color=false`

```@repl ex_pinning
using ThreadPinning
pinthreads(:rand; hyperthreads=true) # hide
threadinfo(; color=false)
```

```@repl ex_pinning
pinthreads(:compact)
threadinfo(; color=false)
```

```@repl ex_pinning
pinthreads(:spread)
threadinfo(; color=false)
```

## Hyperthreading

On a system where hyperthreading is enabled, you will get something like the following (with `color=true`). Below, we consider a dual-socket system where each CPU has 128 hardware threads (64 CPU-cores + hyperthreading) and start julia with 40 threads, i.e. `julia -t 40`.

![threadinfo.png](threadinfo.png)

Note that hyperthreads are highlighted with a different color since often times you want to avoid pinning Julia threads to them (of course, there are exceptions).

## Fine-grained control

!!! note
    While we enumerate Julia threads as `1:Threads.nthreads()`, **cpuids start from zero** and are hence (typically) enumerated as `0:Sys.CPU_THREADS-1`!

Apart from the general pinning strategies like e.g. `:compact` or `:spread` you can use [`pinthreads(::AbstractVector{<:Integer})`](@ref) to pin Julia threads to specific cores.

```@repl ex_pinning
pinthreads(5:5+Threads.nthreads()-1)
threadinfo(; color=false)
```

Furthermore, if you want to pin threads individually, there is [`pinthread(threadid, cpuid)`](@ref)
```@repl ex_pinning
pinthread(1,39)
threadinfo(; color=false)
```

If you want to pin the calling thread you can simply use [`pinthread(cpuid)`](@ref).

## Environment variables

**Pinning:**

The following environment variables can be used to specify the desired pinning before starting Julia. Julia Threads will then automatically get pinned during the initialization of the ThreadPinning package, i.e. when calling `using ThreadPinning`.
* `JULIA_PIN`: Can be set to any binding / pinning strategy symbol supported by [`pinthreads`](@ref), e.g. `JULIA_PIN=compact`.
* `JULIA_PLACES` (optional): Can be set to any places symbol supported by [`pinthreads`](@ref), e.g. `JULIA_PLACES=sockets`.

**Other:**
* `JULIA_TP_AUTOUPDATE`: When set to `false`, ThreadPinning.jl won't query lscpu when `using` the package but will use the system information obtained during precompilation. This can drastically reduce the `using ThreadPinning` time but is only safe if the package is used on the same system used for precompilation (i.e. often not the case on clusters!).