# "Low-level" pinthreads
"""
    pinthread(cpuid::Integer; warn::Bool = true)

Pin the calling Julia thread to the CPU with id `cpuid`.
"""
function pinthread(cpuid::Integer; warn::Bool = true)
    if warn
        (minimum(cpuids_all()) ≤ cpuid ≤ maximum(cpuids_all())) ||
            throw(ArgumentError("cpuid is out of bounds ($(minimum(cpuids_all())) ≤ cpuid ≤ $(maximum(cpuids_all())))."))
        _check_environment()
    end
    FIRST_PIN[] = false
    return uv_thread_setaffinity(cpuid)
end

"""
    pinthread(threadid::Integer, cpuid::Integer; kwargs...)

Pin the given Julia thread (`threadid`) to the CPU with ID `cpuid`.
"""
function pinthread(threadid::Integer, cpuid::Integer; kwargs...)
    fetch(@tspawnat threadid pinthread(cpuid; kwargs...))
    return nothing
end

"""
    pinthreads(cpuids::AbstractVector{<:Integer}[; warn])
Pins the first `1:length(cpuids)` Julia threads to the CPUs with ids `cpuids`.
Note that `length(cpuids)` may not be larger than `Threads.nthreads()`.

For more information see `pinthread`.
"""
function pinthreads(cpuids::AbstractVector{<:Integer}; warn::Bool = true, force = true)
    if force || first_pin_attempt()
        warn && _check_environment()
        ncpuids = length(cpuids)
        ncpuids ≤ nthreads() ||
            throw(ArgumentError("length(cpuids) must be ≤ Threads.nthreads()"))
        (minimum(cpuids) ≥ minimum(cpuids_all()) && maximum(cpuids) ≤ maximum(cpuids_all())) ||
            throw(ArgumentError("All cpuids must be ≤ $(maximum(cpuids_all())) and ≥ $(minimum(cpuids_all()))."))

        @threads :static for tid in 1:ncpuids
            pinthread(cpuids[tid]; warn = false)
        end
    end
    return nothing
end

# Types
abstract type Places end
struct CPUThreads <: Places end
struct Cores <: Places end
struct NUMA <: Places end
struct Sockets <: Places end

abstract type PinningStrategy end
struct CompactBind <: PinningStrategy end
struct SpreadBind <: PinningStrategy end
struct RandomBind <: PinningStrategy end
struct CurrentBind <: PinningStrategy end

# Places logic
_places_symbol2singleton(s::Symbol) = _places_symbol2singleton(Val{s})
_places_symbol2singleton(::Type{Val{T}}) where {T} = nothing # fallback
_places_symbol2singleton(::Type{Val{:threads}}) = CPUThreads()
_places_symbol2singleton(::Type{Val{:cputhreads}}) = CPUThreads()
_places_symbol2singleton(::Type{Val{:cores}}) = Cores()
_places_symbol2singleton(::Type{Val{:numa}}) = NUMA()
_places_symbol2singleton(::Type{Val{:NUMA}}) = NUMA()
_places_symbol2singleton(::Type{Val{:sockets}}) = Sockets()

is_valid_places_symbol(s::Symbol) = !isnothing(_places_symbol2singleton(s))

getplaces_cpuids(s::Symbol) = getplaces_cpuids(_places_symbol2singleton(s))
function getplaces_cpuids(::CPUThreads)
    # if hyperthreading_is_enabled()
    #     cpuids_nonht = filter(!ishyperthread, cpuids_all())
    #     cpuids_ht = filter(ishyperthread, cpuids_all())
    #     [[cpuid] for cpuid in interweave_uneven(cpuids_nonht, cpuids_ht)]
    # else
    #     [[cpuid] for cpuid in cpuids_all()]
    # end
    return [[cpuid] for cpuid in cpuids_all()]
end
function getplaces_cpuids(::Cores)
    if hyperthreading_is_enabled()
        [[cpuid] for cpuid in filter(!ishyperthread, cpuids_all())] # should HT be entirely ignored here?
    else
        [[cpuid] for cpuid in cpuids_all()]
    end
end
getplaces_cpuids(::NUMA) = cpuids_per_numa()
getplaces_cpuids(::Sockets) = cpuids_per_socket()
getplaces_cpuids(v::AbstractVector{<:AbstractVector{<:Integer}}) = v

_default_places(::PinningStrategy) = Cores() # fallback
_default_places(::CompactBind) = Cores()
_default_places(::SpreadBind) = Sockets()
_default_places(::RandomBind) = CPUThreads()

# Binding strategy logic
_pinning_symbol2singleton(s::Symbol)::Union{PinningStrategy, Nothing} = _pinning_symbol2singleton(Val{
                                                                                                      s
                                                                                                      })
_pinning_symbol2singleton(::Type{Val{T}}) where {T} = nothing # fallback
_pinning_symbol2singleton(::Type{Val{:compact}}) = CompactBind()
_pinning_symbol2singleton(::Type{Val{:close}}) = CompactBind()
_pinning_symbol2singleton(::Type{Val{:spread}}) = SpreadBind()
_pinning_symbol2singleton(::Type{Val{:scatter}}) = SpreadBind()
_pinning_symbol2singleton(::Type{Val{:random}}) = RandomBind()
_pinning_symbol2singleton(::Type{Val{:current}}) = CurrentBind()

is_valid_pinning_symbol(s::Symbol) = !isnothing(_pinning_symbol2singleton(s))

function getcpuids_pinning(s::Symbol, places; kwargs...)
    getcpuids_pinning(_pinning_symbol2singleton(s), places; kwargs...)
end
function getcpuids_pinning(::PinningStrategy, places; kwargs...)
    throw(ArgumentError("Unknown pinning strategy."))
end
getcpuids_pinning(::CompactBind, places; kwargs...) = reduce(vcat, getplaces_cpuids(places))
getcpuids_pinning(::SpreadBind, places; kwargs...) = interweave(getplaces_cpuids(places)...)
function getcpuids_pinning(::RandomBind, places; kwargs...)
    reduce(vcat, Random.shuffle(getplaces_cpuids(places)))
end
getcpuids_pinning(::CurrentBind, args...; kwargs...) = getcpuids()

# High-level pinthreads
"""
    pinthreads(pinning[; places, nthreads=Threads.nthreads(), warn=true, force=true, kwargs...])
Pins the first `1:nthreads` Julia threads according to the given `pinning` strategy to the given `places`.
Per default, a reasonable value for `places` is chosen based on the given `pinning` strategy.

**Pinning strategies** (`pinning`):
* `:compact` or `:close`: pins to `places` one after another.
* `:spread` or `scatter`: pins to `places` in an alternating / round robin fashion.
* `:random`: shuffles the given `places` and then pins to them compactly.
* `:current`: pins threads to the cpu threads where they are currently running (ignores `places`).

**Places** (`places`):
* `:cores` or `Cores()`: all the cores of the system
* `:threads`, `:cputhreads`, or `CPUThreads()`: all the cpu threads of the system (equal to `:cores` if there is one cpu thread per core, e.g. no hyperthreading)
* `:sockets` or `Sockets()`: the sockets of the system
* `:numa` or `NUMA()`: the NUMA domains of the system
* An `AbstractVector{<:AbstractVector{<:Integer}}` of cpu ids that defines the places explicitly

If `force=false` the `pinthreads` call will only pin threads if this is the first attempt to pin threads with ThreadPinning.jl.
Otherwise it will be a no-op. This may be particularly useful for packages that merely want to specify a "default pinning".
"""
function pinthreads(pinning::PinningStrategy;
                    places::Union{Places, Symbol,
                                  AbstractVector{<:AbstractVector{<:Integer}}} = _default_places(pinning),
                    nthreads = Base.Threads.nthreads(), warn::Bool = true, force = true,
                    kwargs...)
    if force || first_pin_attempt()
        warn && _check_environment()
        cpuids = getcpuids_pinning(pinning, places; kwargs...)
        if nthreads <= length(cpuids)
            @views pinthreads(cpuids[1:nthreads]; warn = false)
        else
            @warn("More Julia threads than CPU IDs to bind to. Some CPU threads will host multiple Julia threads!")
            idcs = mod1.(1:nthreads, length(cpuids)) # PBC
            @views pinthreads(cpuids[idcs]; warn = false)
        end
    end
    return nothing
end
function pinthreads(pinning::Symbol; kwargs...)
    if !is_valid_pinning_symbol(pinning)
        throw(ArgumentError("Unknown pinning strategy: $(pinning)"))
    end

    pinthreads(_pinning_symbol2singleton(pinning); kwargs...)
end

"""
Unpins all Julia threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any Julia thread from one CPU thread to another.
"""
function unpinthreads()
    masksize = uv_cpumask_size()
    cpumask = zeros(Cchar, masksize)
    fill!(cpumask, 1)
    for tid in 1:nthreads()
        uv_thread_setaffinity(tid, cpumask)
    end
    return nothing
end

"""
Unpins the Julia thread with the given `threadid` by setting the affinity mask to all unity.
Afterwards, the OS is free to move the Julia thread from one CPU thread to another.
"""
function unpinthread(threadid::Integer)
    masksize = uv_cpumask_size()
    cpumask = zeros(Cchar, masksize)
    fill!(cpumask, 1)
    return uv_thread_setaffinity(threadid, cpumask)
end

# Potentially throw warnings if the environment is such that thread pinning might not work.
function _check_environment()
    if Base.Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
        @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
    end
    return nothing
end

# global "constants"
const FIRST_PIN = Ref{Bool}(true)

first_pin_attempt() = FIRST_PIN[]
function forget_pin_attempts()
    FIRST_PIN[] = true
    return nothing
end
