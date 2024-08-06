# API - Pinning

## Pinning

```@docs
pinthreads
pinthread
with_pinthreads
unpinthreads
unpinthread
setaffinity
setaffinity_cpuids
```

## Pinning - OpenBLAS
```@docs
openblas_pinthreads
openblas_pinthread
openblas_unpinthreads
openblas_unpinthread
openblas_setaffinity
openblas_setaffinity_cpuids
```

## Pinning - MPI

```@docs
mpi_pinthreads
```

## Pinning - LIKWID

Besides [`pinthreads`](@ref), we offer [`pinthreads_likwidpin`](@ref) which, ideally, should handle all inputs that are supported by the `-c` option of [`likwid-pin`](https://github.com/RRZE-HPC/likwid/wiki/Likwid-Pin) (e.g. `S0:1-3@S1:2,4,5` or `E:N:4:2:4`). If you encounter an input that doesn't work as expected, please file an issue.

```@docs
pinthreads_likwidpin
likwidpin_to_cpuids
likwidpin_domains
```
