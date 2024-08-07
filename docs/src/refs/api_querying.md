# [API - Querying](@id api_querying)

## `threadinfo`

```@docs
threadinfo
```

## Querying

```@docs
getcpuids
getcpuid
ispinned
getispinned
getaffinity
printaffinity
printaffinities
visualize_affinity
getnumanode
getnumanodes
```

## [Querying - Logical](@id api_logical)
```@docs
core
numa
socket
node
cores
numas
sockets
ThreadPinning.cpuids
ThreadPinning.id
ThreadPinning.cpuid
```

## Querying - System
```@docs
ncputhreads
ncores
nnuma
nsockets
ncorekinds
nsmt
isefficiencycore
ishyperthread
hyperthreading_is_enabled
```

## Querying - OpenBLAS

```@docs
openblas_getaffinity
openblas_getcpuids
openblas_getcpuid
openblas_ispinned
openblas_printaffinities
openblas_printaffinity
```

## [Querying - MPI](@id api_mpi_querying)

```@docs
mpi_getcpuids
mpi_gethostnames
mpi_getlocalrank
```

## [Querying - Distributed.jl](@id api_distributed_querying)

```@docs
distributed_getcpuids
distributed_gethostnames
distributed_getispinned
```
