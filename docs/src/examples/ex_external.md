# External Pinning Tools

```julia
$ cat getcpuids.jl 
using ThreadPinning
println(getcpuids())

$ cat getcpuids_affinitymask.jl 
using ThreadPinning
pinthreads(:affinitymask)
println(getcpuids())
```

## `taskset`

```julia
$ taskset --cpu-list 0-9 julia --project -t 10 getcpuids.jl
[1, 3, 3, 2, 4, 7, 0, 5, 5, 6]
```

Note that some Julia threads may run on the same CPU-thread(!) which is likely not desired. You can use `pinthreads(:affinitymask)` to pin the Julia threads in accordance with the external affinity mask.

```julia
$ taskset --cpu-list 0-9 julia --project -t 10 getcpuids_affinitymask.jl
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
```

## `numactl`

```julia
$ numactl --physcpubind=0-9 julia --project -t 10 getcpuids.jl 
[6, 2, 0, 5, 4, 1, 3, 7, 6, 5]
```

Note that some Julia threads may run on the same CPU-thread(!) which is likely not desired. You can use `pinthreads(:affinitymask)` to pin the Julia threads in accordance with the external affinity mask.

```julia
$ numactl --physcpubind=0-9 julia --project -t 10 getcpuids_affinitymask.jl 
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
```

## SLURM

!!! note
    SLURM settings vary a lot between clusters, in particular affinity related settings. In the following, we visualize the affinity mask set by SLURM at the top of the output files (`B` means "this CPU can be used" whereas `-` indicates "this CPU can't be used" and vertical lines indicate different domains.). Be wary that the same job scripts might not set affinity masks on your cluster!

```julia
$ cat slurm.jl 
#!/usr/bin/env sh
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task 10
#SBATCH -o sl_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00
#=
srun -n 1 julia --project -t 10 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#

using ThreadPinning
# pinthreads(:affinitymask)
println(getcpuids())
```

```
$ cat sl_2872979.out
cpu-bind=MASK - n2fpga19, task  0  0 [306877]: mask |--------|--------||--------|--------||--------|--------||--------|--------||||BBBBBBBB|BB------||--------|--------||--------|--------||--------|--------|  set
cpu-bind=MASK - n2fpga19, task  0  0 [306905]: mask |--------|--------||--------|--------||--------|--------||--------|--------||||BBBBBBBB|BB------||--------|--------||--------|--------||--------|--------|  set
[70, 65, 73, 71, 72, 68, 66, 64, 72, 67]
```

Note that while the implicit affinity mask is generally respected, some Julia threads may run on the same CPU-thread(!) which is likely not desired. You can use `pinthreads(:affinitymask)` to fix this.

```
$ cat sl_2872992.out 
cpu-bind=MASK - n2fpga19, task  0  0 [308377]: mask |--------|--------||--------|--------||--------|--------||--------|--------||||BBBBBBBB|BB------||--------|--------||--------|--------||--------|--------|  set
cpu-bind=MASK - n2fpga19, task  0  0 [308405]: mask |--------|--------||--------|--------||--------|--------||--------|--------||||BBBBBBBB|BB------||--------|--------||--------|--------||--------|--------|  set
[64, 65, 66, 67, 68, 69, 70, 71, 72, 73]
```

## [Comments for Julia 1.9](@id julia19)

As of Julia 1.9, exernal affinity masks are automatically respected ([relevant PR](https://github.com/JuliaLang/julia/pull/42340)) but `pinthreads(:affinitymask)` is still useful to guarantee that Julia threads run on different CPU-threads (within the mask).

```julia
$ cat getcpuids_all.jl 
using ThreadPinning
ThreadPinning.openblas_print_affinity_masks() # requires Julia >= 1.9
println(getcpuids())
```

```julia
$ OPENBLAS_NUM_THREADS=10 taskset --cpu-list 0-9 julia +1.9 --project -t 10 getcpuids_all.jl
Julia threadid: 1
1:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
2:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
3:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
4:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
5:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
6:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
7:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
8:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
9:   |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|
10:  |11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000|

[1, 7, 8, 2, 3, 0, 6, 4, 4, 7]
```

Note that while the Julia threads respect the affinity mask, some Julia threads may run on the same CPU-thread(!). Furthermore, note that the OpenBLAS threads also respect the affinity mask.

### `-tauto`

Use `-tauto` to automatically set the number of Julia threads such that it matches the external affinity mask.

```
$ taskset --cpu-list 0-9 julia +1.9 -tauto --project -E 'Threads.nthreads()'
10
```