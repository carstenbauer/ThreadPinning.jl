# [Why Pin Julia Threads?](@id why)

Because
* [it effects performance (MFlops/s), in particular on HPC clusters with multiple NUMA domains](https://github.com/JuliaPerf/BandwidthBenchmark.jl#flopsscaling)
* [it allows you to utilize performance counters inside of CPU-cores for hardware-performance monitoring](https://www.youtube.com/watch?v=l2fTNfEDPC0)
* it makes performance benchmarks more reliable (i.e. less random/noisy)
* ...