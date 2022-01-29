# ThreadPinning.jl

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

### Without color support

```julia
julia> using ThreadPinning, Hwloc # Hwloc is optional

julia> threadinfo(color=false)

| 0,_,_,_,_,_,_,_,_,_,_,11,12,13,_,_,_,_,_,_ |
| 20,21,22,23,24,25,26,27,28,_,30,31,32,33,34,35,_,37,_,_ |

# = Julia thread, | = Package seperator

Julia threads: 20
Occupied cores: 20
Thread-Core mapping:
  1 => 0,  2 => 26,  3 => 28,  4 => 12,  5 => 20,  ...

julia> pinthreads(:compact)

julia> threadinfo(color=false)

| 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19 |
| _,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_ |

# = Julia thread, | = Package seperator

Julia threads: 20
Occupied cores: 20
Thread-Core mapping:
  1 => 0,  2 => 1,  3 => 2,  4 => 3,  5 => 4,  ...

julia> pinthreads(:scatter)

julia> threadinfo(color=false)

| 0,1,2,3,4,5,6,7,8,9,_,_,_,_,_,_,_,_,_,_ |
| 20,21,22,23,24,25,26,27,28,29,_,_,_,_,_,_,_,_,_,_ |

# = Julia thread, | = Package seperator

Julia threads: 20
Occupied cores: 20
Thread-Core mapping:
  1 => 0,  2 => 20,  3 => 1,  4 => 21,  5 => 2,  ...
```

## Explanation

We use libc's [sched_getcpu](https://man7.org/linux/man-pages/man3/sched_getcpu.3.html) to query the CPU-core ID for a thread and libuv's [uv_thread_setaffinity](https://github.com/clibs/uv/blob/master/docs/src/threading.rst) to set the affinity of a thread.


## Noteworthy Alternatives

* Setting `JULIA_EXCLUSIVE=1` will make julia use compact pinning automatically (no external tool needed!)
* [`pinthread` / `pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`

## Acknowledgements

* CI infrastructure is provided by the [Paderborn Center for Parallel Computing (PC²)](https://pc2.uni-paderborn.de/)
