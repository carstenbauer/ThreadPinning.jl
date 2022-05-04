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