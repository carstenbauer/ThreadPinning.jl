# [Process Affinity Mask](@id exaffinitymask)

In scenarios where the Julia process has a specific affinity mask, e.g. when running under `taskset`, `numactl`, or (perhaps) SLURM, you may want to pin your Julia threads in accordance with this affinity mask. To that end, we provide [`pinthreads(:affinitymask)`](@ref), which pins Julia threads to non-masked CPU-threads (in order, hyperthreads are only used if necessary).

For the demonstration below, we consider the following Julia script:
```julia
$ cat check.jl 
using ThreadPinning
if length(ARGS) > 0 && ARGS[1] == "pin"
    pinthreads(:affinitymask)
end
println(getcpuids())
println("no double occupancies: ", length(unique(getcpuids())) == length(getcpuids()))
println("in order: ", issorted(getcpuids()))
```

## [`taskset`](@id tasksetheading)

Let's use `taskset --cpu-list` to set the affinity of the Julia process.

```julia
$ taskset --cpu-list 0-24 julia --project -t 25 check.jl
[13, 13, 4, 5, 6, 7, 8, 11, 15, 14, 12, 16, 18, 19, 0, 10, 3, 9, 24, 2, 17, 20, 1, 21, 21]
no double occupancies: false
in order: false
```

Note that

1) some Julia threads **may** run on the same CPU-thread(!) (which is almost certainly not desired), and
2) the order of the Julia thread to CPU-thread mapping is arbitrary (and non-deterministic).

We can remedy both points with `pinthreads(:affinitymask)`:

```julia
$ taskset --cpu-list 0-24 julia --project -t 25 check.jl pin
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
no double occupancies: true
in order: true
```

## `numactl`

The same comments as made for [`taskset`](@ref tasksetheading) above also apply to `numactl --physcpubind`. Without `pinthreads(:affinitymask)`:

```julia
$ numactl --physcpubind=0-24 julia --project -t 25 check.jl 
[6, 10, 7, 13, 14, 15, 8, 16, 19, 0, 5, 2, 3, 4, 18, 1, 9, 17, 20, 20, 12, 20, 10, 20, 11]
no double occupancies: false
in order: false
```

With `pinthreads(:affinitymask)`:

```julia
$ numactl --physcpubind=0-24 julia --project -t 25 check.jl pin
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
no double occupancies: true
in order: true
```

## SLURM

!!! note
    SLURM settings vary a lot between clusters, in particular affinity related settings. In the following, we visualize the affinity mask set by SLURM at the top of the output files (`B` means "this CPU can be used" whereas `-` indicates "this CPU can't be used" and vertical lines indicate different domains.). Be wary that the same job scripts might not set affinity masks on your cluster!

```julia
$ cat slurm_basic.jl 
#!/usr/bin/env sh
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task 25
#SBATCH -o sl_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00

srun -n 1 julia --project -t 25 check.jl 
```

Without `pinthreads(:affinitymask)`:
```
$ cat sl_2374255.out 
cpu-bind=MASK - cn-0181, task  0  0 [1410285]: mask |BBBBBBBBBBBBBBBBBBBB||||BBBBB---------------|  set
cpu-bind=MASK - cn-0181, task  0  0 [1410316]: mask |BBBBBBBBBBBBBBBBBBBB||||BBBBB---------------|  set
[11, 16, 17, 2, 15, 18, 19, 13, 3, 4, 5, 6, 7, 10, 9, 8, 14, 11, 20, 0, 12, 13, 4, 2, 1]
no double occupancies: false
in order: false
```

Note that

1) some Julia threads **may** run on the same CPU-thread(!) (which is almost certainly not desired), and
2) the order of the Julia thread to CPU-thread mapping is arbitrary (and non-deterministic).

We can remedy both points with `pinthreads(:affinitymask)`:
```
$ cat sl_2374256.out 
cpu-bind=MASK - cn-0197, task  0  0 [1507377]: mask |BBBBBBBBBBBBBBBBBBBB||||BBBBB---------------|  set
cpu-bind=MASK - cn-0197, task  0  0 [1507410]: mask |BBBBBBBBBBBBBBBBBBBB||||BBBBB---------------|  set
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
no double occupancies: true
in order: true
```

## Supplement: `-tauto` (Julia >= 1.9)

For Julia >= 1.9 you can use `-tauto` to automatically set the number of Julia threads such that it matches the external affinity mask ([relevant PR](https://github.com/JuliaLang/julia/pull/42340)). This is particularly useful when using SLURM, but, for simplicity, we can also showcase it with `taskset`:

```
$ taskset --cpu-list 0-24 julia +1.9 -tauto --project check.jl pin
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
no double occupancies: true
in order: true
```

```
$ taskset --cpu-list 0-11 julia +1.9 -tauto --project check.jl pin
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
no double occupancies: true
in order: true
```