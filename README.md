# ThreadPinning.jl

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://carstenbauer.github.io/ThreadPinning.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://carstenbauer.github.io/ThreadPinning.jl/stable

[ci-img]: https://github.com/carstenbauer/ThreadPinning.jl/actions/workflows/CI.yml/badge.svg?branch=main
[ci-url]: https://github.com/carstenbauer/ThreadPinning.jl/actions/workflows/CI.yml?query=branch%3Amain

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

*Readily pin Julia threads to CPU processors*

| **Documentation**                                                               | **Build Status**                                                                                |  **Quality**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][ci-img]][ci-url] [![][cov-img]][cov-url] | ![][lifecycle-img] [![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle) |

## What is this about? (10 minutes)

Check out my lightning talk that I gave as part of [JuliaCon 2023](https://juliacon.org/2023/) at MIT.

[![](https://img.youtube.com/vi/6Whc9XtlCC0/0.jpg)](https://youtu.be/6Whc9XtlCC0)

## Quick Demo

Dual-socket system where each CPU has 40 hardware threads (20 CPU-cores with 2-way [SMT](https://en.wikipedia.org/wiki/Simultaneous_multithreading)).

<img src="https://github.com/carstenbauer/ThreadPinning.jl/raw/main/docs/src/examples/threadinfo_ht_long.png" width=900px>

Check out the [documentation](https://carstenbauer.github.io/ThreadPinning.jl/stable) to learn how to use ThreadPinning.jl.

## Installation

The package is registered. Hence, you can simply use
```
] add ThreadPinning
```
to add the package to your Julia environment.

Note that **only Linux is fully supported**. On other operating systems, all pinning calls (e.g. `pinthreads`) will turn into no-ops but things like `threadinfo()` should work (with limitations).

## Documentation

For more information, please find the [documentation](https://carstenbauer.github.io/ThreadPinning.jl/stable) here.
