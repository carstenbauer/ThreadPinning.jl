# Pinning OpenBLAS Threads

Almost all of the pinning (and querying) functions have counterparts that are prefixed by `openblas_`. You can use these variants to control OpenBLAS threads in the same way as the regular Julia threads. Example: 

```
using ThreadPinning
openblas_pinthreads(:cores)
```

As for visualization, you can use `threadinfo(; blas=true)` to visualize the placement of the OpenBLAS threads instead of Julia threads.

!!! note
    For technical reasons, we can't query the CPU-thread on which an OpenBLAS thread is running before the thread has been pinned. For this reason, `openblas_getcpuid`, and all functionality that relies on it, will only work after pinning. Otherwise, these calls will throw an error.
    Note that printing the affinities of the OpenBLAS threads (`openblas_printaffinities`) always works.

![openblas](openblas.png)

## Beware: Interaction between Julia threads and BLAS threads

If one runs a multithreaded Julia code that, on each thread, performs linear algebra operations (BLAS/LAPACK calls) one can easily run into performance issues due to an oversubscription of cores by Julia and BLAS threads (see [Background information](@ref blas_background) below for more information). Fortunately, ThreadPinning.jl provides some (basic) autochecking functionality that highlights potential problems and suggests improvements. Concretely, you can provide the keyword argument `hints=true` to [`threadinfo`](@ref). In this case, we try to provide concrete notes and warnings that (hopefully) help you to tune your thread-related settings.

### [Background information](@id blas_background)

Relevant discourse threads, see [here](https://discourse.julialang.org/t/matrix-multiplication-is-slower-when-multithreading-in-julia/56227/12?u=carstenbauer) and [here](https://discourse.julialang.org/t/regarding-the-multithreaded-performance-of-openblas/75450/5?u=carstenbauer).

#### OpenBLAS

* If `OPENBLAS_NUM_THREADS=1`, OpenBLAS uses the calling Julia thread(s) to run BLAS computations, i.e. it "reuses" the Julia thread that runs a computation.

* If `OPENBLAS_NUM_THREADS=N>1`, OpenBLAS creates and manages its own pool of BLAS threads (`N` in total). There is one BLAS thread pool (for all Julia threads).

* **Julia default:** `OPENBLAS_NUM_THREADS=8` (Julia version ≤ 1.8) and `OPENBLAS_NUM_THREADS=Sys.CPU_THREADS` (Julia version ≥ 1.8).

When you start Julia in multithreaded mode, i.e. `julia -tX` or `JULIA_NUM_THREADS=X`, it is generally recommended to set `OPENBLAS_NUM_THREADS=1` or, equivalently, `BLAS.set_num_threads(1)`. Given the behavior above, increasing the number of BLAS threads to `N>1` can very easily lead to worse performance, in particular when `N<<X`! Hence, if you want to or need to deviate from unity, make sure to "jump" from `OPENBLAS_NUM_THREADS=1` to `OPENBLAS_NUM_THREADS=# of cores` or similar.

#### Intel MKL

* Given `MKL_NUM_THREADS=N`, MKL starts `N` BLAS threads **per** Julia thread that makes a BLAS call.

* **Default:** `MKL_NUM_THREADS=# of physical cores`, i.e. excluding hyperthreads. (Verified experimentally but would be good to find a source for this.)

When you start Julia in multithreaded mode, i.e. `julia -tX` or `JULIA_NUM_THREADS=X`, we recommend to set `MKL_NUM_THREADS=(# of cores)/X` or, equivalently, `BLAS.set_num_threads((# of cores)/X)` (after `using MKL`). Unfortunately, the default is generally suboptimal as soon as you don't run Julia with a single thread. Hence, make sure to tune the settings appropriately.

**Side comment:** It is particularly bad / confusing that OpenBLAS and MKL behave very differently for multithreaded Julia.

!!! warning
    Be aware that calling an MKL function (for the first time) can spoil the pinning of Julia threads! A concrete example is discussed [here](https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560). TLDR: You want to make sure that `MKL_DYNAMIC=false`. Apart from setting the environment variable you can also dynamically call [`ThreadPinning.MKL.mkl_set_dynamic(0)`](@ref). Note that, by default, ThreadPinning.jl will warn you if you call one of the pinning functions while `MKL_DYNAMIC=true`.