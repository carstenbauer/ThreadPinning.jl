# ThreadPinning.jl

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://carstenbauer.github.io/ThreadPinning.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://carstenbauer.github.io/ThreadPinning.jl/stable

[ci-img]: https://git.uni-paderborn.de/pc2-ci/julia/ThreadPinning-jl/badges/main/pipeline.svg?key_text=CI@PC2
[ci-url]: https://git.uni-paderborn.de/pc2-ci/julia/ThreadPinning-jl/-/pipelines

[cov-img]: https://codecov.io/gh/carstenbauer/ThreadPinning.jl/branch/main/graph/badge.svg?token=Ze61CbGoO5
[cov-url]: https://codecov.io/gh/carstenbauer/ThreadPinning.jl

[lifecycle-img]: https://img.shields.io/badge/lifecycle-stable-black.svg

[code-style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[code-style-url]: https://github.com/invenia/BlueStyle

<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
-->

*Pin Julia threads to CPU processors ("hardware threads")*

| **Documentation**                                                               | **Build Status**                                                                                |  **Quality**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][ci-img]][ci-url] [![][cov-img]][cov-url] | ![][lifecycle-img] [![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle) |

## Demonstration

Dual-socket system where each CPU has 40 hardware threads (20 CPU-cores with 2-way SMT).

<img src="https://github.com/carstenbauer/ThreadPinning.jl/raw/main/docs/src/examples/threadinfo_ht_long.png" width=900px>

Check out the [documentation](https://carstenbauer.github.io/ThreadPinning.jl/stable) to learn how to use ThreadPinning.jl.

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

By default, ThreadPinning.jl queries the system topology using `lscpu` on startup (i.e. at runtime). This is quite costly but is unfortunately necessary since you might have precompiled the package on one machine and use it from another (think e.g. login and compute nodes of a HPC cluster). However, you can tell ThreadPinning.jl to permanently skip this autoupdate at runtime and to always use the system topology that was present at compile time (i.e. when precompiling the package). This is perfectly save if you don't use the same Julia depot on different machines, in particular if you're a "standard user" that uses Julia on a desktop computer or laptop, and can reduce the package load time significantly. To do so, simply call `ThreadPinning.Prefs.set_autoupdate(false)`.

## Why pin Julia threads?

Because
* [it effects performance (MFlops/s), in particular on HPC clusters with multiple NUMA domains](https://github.com/JuliaPerf/BandwidthBenchmark.jl#flopsscaling)
* [it allows you to utilize performance counters inside of CPU cores for hardware-performance monitoring](https://www.youtube.com/watch?v=l2fTNfEDPC0)
* it makes performance benchmarks more reliable (i.e. less random/noisy)
* ...

## Documentation

For more information, please find the [documentation](https://carstenbauer.github.io/ThreadPinning.jl/stable) here.

## Acknowledgements

CI infrastructure is provided by the [Paderborn Center for Parallel Computing (PC²)](https://pc2.uni-paderborn.de/)
