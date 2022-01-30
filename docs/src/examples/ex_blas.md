# Julia Threads + BLAS Threads

This page is concerned with the (performance) issues that can occur if you run a multithreaded Julia code that, on each thread, performs linear algebra operations (BLAS/LAPACK calls). In this case, one must ensure that cores aren't oversubscribe due to the two levels of multithreading.

Relevant discourse threads, see [here](https://discourse.julialang.org/t/matrix-multiplication-is-slower-when-multithreading-in-julia/56227/12?u=carstenbauer) and [here](https://discourse.julialang.org/t/regarding-the-multithreaded-performance-of-openblas/75450/5?u=carstenbauer).

## OpenBLAS

### What you need to know

* If `OPENBLAS_NUM_THREADS=1`, OpenBLAS uses the calling Julia thread(s) to run BLAS computations, i.e. it "reuses" the Julia thread that runs a computation.

* If `OPENBLAS_NUM_THREADS=N>1`, OpenBLAS creates and manages its own pool of BLAS threads (`N` in total). There is one BLAS thread pool (for all Julia threads).

* **Julia default:** `OPENBLAS_NUM_THREADS=8` (Julia version ≤ 1.8) and `OPENBLAS_NUM_THREADS=Sys.CPU_THREADS` (Julia version ≥ 1.8).

When you start Julia in multithreaded mode, i.e. `julia -tX` or `JULIA_NUM_THREADS=X`, it is generally recommended to set `OPENBLAS_NUM_THREADS=1` or, equivalently, `BLAS.set_num_threads(1)`. Given the behavior above, increasing the number of BLAS threads to `N>1` can very easily lead to worse performance, in particular when `N<<X`! Hence, if you want to or need to deviate from unity, make sure to "jump" from `OPENBLAS_NUM_THREADS=1` to `OPENBLAS_NUM_THREADS=# of cores` or similar.

### `threadinfo(; blas=true, hints=true)`

To automatically detect whether you (potentially) have suboptimal settings, you can provide the keyword argument `blas=true` to [`threadinfo`](@ref). This will show some of your OpenBLAS settings and color-indicate whether they are likely to be ok (green) or suboptimal (red). If you also provide `hints=true`, ThreadPinning.jl will try to provide concrete notes and warnings that (hopefully) help you to tune your settings.

![openblas](openblas.png)

## Intel MKL

### What you need to know

* Given `MKL_NUM_THREADS=N`, MKL starts `N` BLAS threads **per** Julia thread that makes a BLAS call.

* **Default:** `MKL_NUM_THREADS=# of physical cores`, i.e. excluding hyperthreads. (Verified experimentally but would be good to find a source for this.)

When you start Julia in multithreaded mode, i.e. `julia -tX` or `JULIA_NUM_THREADS=X`, we recommend to set `MKL_NUM_THREADS=(# of cores)/X` or, equivalently, `BLAS.set_num_threads((# of cores)/X)` (after `using MKL`). Unfortunately, the default is generally suboptimal as soon as you don't run Julia with a single thread. Hence, make sure to tune the settings appropriately.

**Side comment:** It is particularly bad / confusing that OpenBLAS and MKL behave very differently for multithreaded Julia.

### `threadinfo(; blas=true, hints=true)`

To automatically detect whether you (potentially) have suboptimal settings, you can provide the keyword argument `blas=true` to [`threadinfo`](@ref). This will show some of your MKL settings and color-indicate whether they are likely to be ok (green) or suboptimal (red). If you also provide `hints=true`, ThreadPinning.jl will try to provide concrete notes and warnings that (hopefully) help you to tune your settings.

![mkl](mkl.png)