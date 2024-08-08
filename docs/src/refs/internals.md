# Internals

!!! warning
    This section isn't part of the official API. Things might change at any point without further notice.

### Utility

```@autodocs
Modules = [ThreadPinning.Utility]
Pages   = ["utility.jl"]
```

### MKL

```@autodocs
Modules = [ThreadPinning.MKL]
Pages   = ["mkl.jl"]
```

### Faking (Test Systems)

```@autodocs
Modules = [ThreadPinning.Faking]
Pages   = ["faking.jl"]
```

#### Example

```julia
julia> using ThreadPinning

julia> threadinfo(; color=false) # host system
Hostname:       login01
CPU(s):         2 x Intel(R) Xeon(R) Gold 6226R CPU @ 2.90GHz
CPU target:     cascadelake
Cores:          32 (32 CPU-threads)
NUMA domains:   4 (8 cores each)

Julia threads:  5

CPU socket 1
  _,_,_,3,_,9,10,_,_,_,_,_,12,_,_,_

CPU socket 2
  _,_,_,_,_,_,_,_,_,_,_,_,_,29,_,_


# = Julia thread, # = >1 Julia thread

(Mapping: 1 => 3, 2 => 29, 3 => 9, 4 => 12, 5 => 10, ...)

julia> ThreadPinning.Faking.start("PerlmutterComputeNode") # <----- Start Faking
[ Info: Using backend hwloc.

julia> threadinfo(; color=false) # fake system
Hostname:       PerlmutterComputeNode
CPU(s):         2 x AMD EPYC 7763 64-Core Processor
CPU target:     znver3
Cores:          128 (256 CPU-threads due to 2-way SMT)
NUMA domains:   8 (16 cores each)

Julia threads:  5

CPU socket 1
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,140, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, 36,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_

CPU socket 2
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, 99,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, 118,246, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_


# = Julia thread, # = Julia thread on HT, # = >1 Julia thread

(Mapping: 1 => 140, 2 => 246, 3 => 118, 4 => 36, 5 => 99, ...)

julia> pinthreads(:cores) # fake pinning

julia> threadinfo(; color=false) # fake system
Hostname:       PerlmutterComputeNode
CPU(s):         2 x AMD EPYC 7763 64-Core Processor
CPU target:     znver3
Cores:          128 (256 CPU-threads due to 2-way SMT)
NUMA domains:   8 (16 cores each)

Julia threads:  5

CPU socket 1
  0,_, 1,_, 2,_, 3,_, 4,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_

CPU socket 2
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_, 
  _,_, _,_, _,_, _,_, _,_, _,_, _,_, _,_


# = Julia thread, # = Julia thread on HT, # = >1 Julia thread

(Mapping: 1 => 0, 2 => 1, 3 => 2, 4 => 3, 5 => 4, ...)

julia> ThreadPinning.Faking.stop()  # <----- Stop Faking

julia> threadinfo(; color=false) # host system
Hostname:       login01
CPU(s):         2 x Intel(R) Xeon(R) Gold 6226R CPU @ 2.90GHz
CPU target:     cascadelake
Cores:          32 (32 CPU-threads)
NUMA domains:   4 (8 cores each)

Julia threads:  5

CPU socket 1
  _,_,_,3,_,9,10,_,_,_,_,_,12,_,_,_

CPU socket 2
  _,_,_,_,_,_,_,_,_,_,_,_,_,29,_,_


# = Julia thread, # = >1 Julia thread

(Mapping: 1 => 3, 2 => 29, 3 => 9, 4 => 12, 5 => 10, ...)
```