# [Julia Threads + BLAS Threads](@id BLAS)

This page is concerned with the performance and pinning issues that can occur if you run a multithreaded Julia code that, on each thread, performs linear algebra operations (BLAS/LAPACK calls). In this case, one must ensure that cores aren't oversubscribe due to the two levels of multithreading.

Relevant discourse threads, see [here](https://discourse.julialang.org/t/matrix-multiplication-is-slower-when-multithreading-in-julia/56227/12?u=carstenbauer) and [here](https://discourse.julialang.org/t/regarding-the-multithreaded-performance-of-openblas/75450/5?u=carstenbauer).

## OpenBLAS

* If `OPENBLAS_NUM_THREADS=1`, OpenBLAS uses the calling Julia thread(s) to run BLAS computations, i.e. it "reuses" the Julia thread that runs a computation.

* If `OPENBLAS_NUM_THREADS=N>1`, OpenBLAS creates and manages its own pool of BLAS threads (`N` in total). There is one BLAS thread pool (for all Julia threads).

* **Julia default:** `OPENBLAS_NUM_THREADS=8` (Julia version ≤ 1.8) and `OPENBLAS_NUM_THREADS=Sys.CPU_THREADS` (Julia version ≥ 1.8).

When you start Julia in multithreaded mode, i.e. `julia -tX` or `JULIA_NUM_THREADS=X`, it is generally recommended to set `OPENBLAS_NUM_THREADS=1` or, equivalently, `BLAS.set_num_threads(1)`. Given the behavior above, increasing the number of BLAS threads to `N>1` can very easily lead to worse performance, in particular when `N<<X`! Hence, if you want to or need to deviate from unity, make sure to "jump" from `OPENBLAS_NUM_THREADS=1` to `OPENBLAS_NUM_THREADS=# of cores` or similar.

## Intel MKL

* Given `MKL_NUM_THREADS=N`, MKL starts `N` BLAS threads **per** Julia thread that makes a BLAS call.

* **Default:** `MKL_NUM_THREADS=# of physical cores`, i.e. excluding hyperthreads. (Verified experimentally but would be good to find a source for this.)

When you start Julia in multithreaded mode, i.e. `julia -tX` or `JULIA_NUM_THREADS=X`, we recommend to set `MKL_NUM_THREADS=(# of cores)/X` or, equivalently, `BLAS.set_num_threads((# of cores)/X)` (after `using MKL`). Unfortunately, the default is generally suboptimal as soon as you don't run Julia with a single thread. Hence, make sure to tune the settings appropriately.

**Side comment:** It is particularly bad / confusing that OpenBLAS and MKL behave very differently for multithreaded Julia.

!!! warning
    Be aware that calling an MKL function (for the first time) can spoil the pinning of Julia threads! A concrete example is discussed [here](https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560). TLDR: You want to make sure that `MKL_DYNAMIC=false`. Apart from setting the environment variable you can also dynamically call [`ThreadPinning.MKL.mkl_set_dynamic(0)`](@ref). Note that, by default, ThreadPinning.jl will warn you if you call one of the pinning functions while `MKL_DYNAMIC=true`.

## `threadinfo(; blas=true, hints=true)`

To automatically detect whether you (potentially) have suboptimal BLAS thread settings, you can provide the keyword arguments `blas=true` and `hints=true` to [`threadinfo`](@ref). An example can be found [here](@ref ex_blas).