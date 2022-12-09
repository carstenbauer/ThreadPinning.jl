# Pinning Julia Threads

Generally speaking, the most important functions are [`pinthreads`](@ref) and [`threadinfo`](@ref).

## Interactive usage

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

### Hyperthreads

On a system where hyperthreading is enabled, you will get something like the following (with `color=true`). Below, we consider a dual-socket system where each CPU has 128 hardware threads (64 CPU-cores + hyperthreading) and start julia with 40 threads, i.e. `julia -t 40`.

![threadinfo.png](threadinfo.png)

Note that hyperthreads are highlighted with a different color since often times you want to avoid pinning Julia threads to them (of course, there are exceptions).

## Non-interactive usage

### [Environment variables](@id envvars)

The following environment variables can be used to specify the desired pinning before starting Julia. Julia Threads will then automatically get pinned during the initialization of the ThreadPinning package, i.e. when calling `using ThreadPinning`.
* `JULIA_PIN`: Can be set to any binding / pinning strategy symbol supported by [`pinthreads`](@ref), e.g. `JULIA_PIN=compact`.
* `JULIA_PLACES` (optional): Can be set to any places symbol supported by [`pinthreads`](@ref), e.g. `JULIA_PLACES=sockets`. Note that explicit `pinthreads` statements take precedence over these environment variables.

### [Julia preferences](@id prefs)

You can more permanently specify a certain pinning setup on a per-project basis via [preferences](https://github.com/JuliaPackaging/Preferences.jl). ThreadPinning.jl provides the relevant functionality in the [`ThreadPinning.Prefs` module](@ref Preferences). Note that environment variables and explicit `pinthreads` statements take precedence over these preferences.

#### Speed up package loading (autoupdate)

By default, ThreadPinning.jl queries the system topology using `lscpu` on startup (i.e. at runtime). This is quite costly but is unfortunately necessary since you might have precompiled the package on one machine and use it from another (think e.g. login and compute nodes of a HPC cluster). However, you can tell ThreadPinning.jl to permanently skip this autoupdate at runtime and to always use the system topology that was present at compile time (i.e. when precompiling the package). This is perfectly save if, e.g., you use the package on your local desktop or laptop only and can reduce the package load time significantly. To do so, simply call `ThreadPinning.Prefs.set_autoupdate(false)`.

## Manual pinning

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

## Default pinning (for packages)

If you're developing a package you may want to provide a reasonable default pinning. If you would naively use `pinthreads` for this you would enforce a certain pinning irrespective of what the user might have specified manually. This is because `pinthreads` by default has the highest precedence. To lower the latter you can set `force=false`, e.g. `pinthreads(:compact; force=false)`. This way, a user can overwrite your default pinning (`:compact` in this example) by using [environment variables](@ref envvars), [preferences](@ref prefs), or calling `pinthreads` manually before running your package code.

## Unpinning

We provide functions [`unpinthread(threadid)`](@ref) and [`unpinthreads()`](@ref) to unpin a specific or all Julia threads, respectively. This is realized by setting the thread affinity mask to all ones.