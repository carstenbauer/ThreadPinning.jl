# Pinning Julia Threads

Generally speaking, the most important functions are [`pinthreads`](@ref) and [`threadinfo`](@ref).

## Typical usage

Below, we consider a dual-socket system with 20 cores per socket and started julia with 20 threads, i.e. `julia -t 20`.

### `color=true` (default)

![threadinfo.png](threadinfo.png)

### `color=false`

```@repl ex_pinning
using ThreadPinning
pinthreads(:rand) # hide
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

On a system where hyperthreading is enabled, you will get something like the following (with `color=true`).

![threadinfo_ht.png](threadinfo_ht.png)

Note that hyperthreads are highlighted with a different color since often times you want to avoid pinning Julia threads to them (of course, there are exceptions).
For example, using `pinthreads(:compact)` might not be what you want since two Julia threads would run on the same core (two hardware threads therein) which might lead to
suboptimal performance. For this reason, we provide `pinthreads(:halfcompact)` which skips every other cpuid. (Feel free to add other / smarter pinning strategies in PRs!)

## Fine-grained control

!!! note
    While we enumerate Julia threads as `1:Threads.nthreads()`, **cpuids start from zero** and are hence enumerated as `0:Sys.CPU_THREADS-1`!

Apart from the general pinning strategies like e.g. `:compact` or `:spread` you can use [`pinthreads(::AbstractVector{<:Integer})`](@ref) to pin Julia threads to specific cores.

```@repl ex_pinning
pinthreads(5:5+Threads.nthreads())
threadinfo(; color=false)
```

Furthermore, if you want to pin threads individually, there is [`pinthread(threadid, cpuid)`](@ref)
```@repl ex_pinning
pinthread(1,39)
threadinfo(; color=false)
```

If you want to pin the calling thread you can simply use [`pinthread(cpuid)`](@ref).