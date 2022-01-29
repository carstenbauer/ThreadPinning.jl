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

*Interactively pin Julia threads to specific cores at runtime*

| **Documentation**                                                               | **Build Status**                                                                                |  **Quality**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-dev-img]][docs-dev-url] | [![][ci-img]][ci-url] [![][cov-img]][cov-url] | ![][lifecycle-img] [![][code-style-img]][code-style-url] |


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

(Dual-socket system with 20 cores per socket, `julia -t 20`)

<img src="https://github.com/carstenbauer/ThreadPinning.jl/raw/main/docs/src/assets/threadinfo.png" width=900px>

## Noteworthy Alternatives

* Setting `JULIA_EXCLUSIVE=1` will make julia use compact pinning automatically (no external tool needed!)
* [`pinthread` / `pinthreads`](https://juliaperf.github.io/LIKWID.jl/dev/examples/dynamic_pinning/) or `likwid-pin` (CLI tool) from [LIKWID.jl](https://github.com/JuliaPerf/LIKWID.jl)
* [This discourse thread](https://discourse.julialang.org/t/thread-affinitization-pinning-julia-threads-to-cores/58069/5) discusses issues with alternatives like `numactl`

## Acknowledgements

* CI infrastructure is provided by the [Paderborn Center for Parallel Computing (PC²)](https://pc2.uni-paderborn.de/)
