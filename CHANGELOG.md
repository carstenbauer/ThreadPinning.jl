ThreadPinning.jl Changelog
=========================

Version 1.0
-------------
- ![Feature][badge-feature] OpenBLAS: Almost all pinning and querying functions now have `openblas_*` analogs that provide (almost) all of the same features as for regular Julia threads. Example: `openblas_pinthreads(:cores)` now works. You can also visualize the placement of OpenBLAS threads via `threadinfo(; blas=true)`. These functions are now also part of the official API (and SemVer).
- ![Feature][badge-feature] Visualizing affinities: Besides `printaffinity` and `printaffinities` there is now is a "pimped" variant `visualize_affinity` which uses the `threadinfo` layout to visualize the affinity.
- ![Feature][badge-feature] MPI: we've added dedicated support for pinning the Julia threads of MPI ranks, which are potentially distributed over multiple nodes.
- ![Breaking][badge-breaking] `threadinfo(; blas=true)` now shows the placement of OpenBLAS threads (same visualization as for regular Julia threads).
- ![Breaking][badge-breaking] Pinning via environment variable (`JULIA_PIN`) now requires a `pinthreads(...; force=false)` call. This is because we've dropped the `__init__` function entirely. The environment variables `JULIA_LIKWID_PIN` has been dropped for now. (Might be reintroduced later.)
- ![Breaking][badge-breaking] Pinning via Julia preferences has been dropped entirely.
- ![Breaking][badge-breaking] `pinthreads_mpi` has been renamed to `mpi_pinthreads` and has a different function signature.
- ![Breaking][badge-breaking] The affinity printing functions are now called `printaffinity` and `printaffinities`.
- ![Breaking][badge-breaking] The family of functions `cpuids_*` has been dropped. Use the logical accessors (e.g. `node`, `socket`, `numa`, etc.) instead.
- ![Breaking][badge-breaking] The family of functions `ncputhreads_per_*` and `ncores_per_*` has been dropped. Use the logical accessors (e.g. `node`, `socket`, `numa`, etc.) in conjuction with `length` as a replacement.
- ![Breaking][badge-breaking] The function `setaffinity` has been split into two functions `setaffinity` (takes a mask array) and `setaffinity_cpuids` (takes an array of CPU IDs).
- ![Breaking][badge-breaking] The core-to-core latency benchmark functionality has been removed (will be moved to a new package soon).
- ![Experimental][badge-experimental] For Julia >= 1.11, there is experimental support for pinning GC threads (`threadpool=:gc`).

[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/Deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/Feature-green.svg
[badge-experimental]: https://img.shields.io/badge/Experimental-yellow.svg
[badge-enhancement]: https://img.shields.io/badge/Enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/Bugfix-purple.svg
[badge-fix]: https://img.shields.io/badge/Fix-purple.svg
[badge-info]: https://img.shields.io/badge/Info-gray.svg
