# ------------ pthread.h ------------
const libpthread = "libpthread"

# WARNING: The choice below might not work on all systems...
# TODO: somehow get info from sched.h
const Cpthread_t = Culong
const Ccpu_set_t_tuple = NTuple{16, UInt64}
struct Ccpu_set_t
    bits::NTuple{16, UInt64}
end
function Base.convert(::Type{BitArray}, cpuset::Ccpu_set_t)
    bitstr = reverse(join(bitstring.(reverse(cpuset.bits))))
    maskarray = BitArray(b == '0' ? false : true for b in bitstr[1:ncputhreads()])
    # maskarray = reduce(vcat, digits.(cpuset.bits, base=2, pad=64))[1:ncputhreads()]
    return maskarray
end
Base.show(io::IO, cpuset::Ccpu_set_t) = print(io, "Ccpu_set_t(", reverse(join(bitstring.(reverse(cpuset.bits)))),")")
function Ccpu_set_t(mask::BitArray)
    n = 64
    maxn = 1024
    length(mask) <= maxn || throw(ArgumentError("Input mask (BitArray) is too large (i.e. has more than $maxn elements)."))
    npad = maxn - length(mask)
    if npad == 0
        mask_padded = reverse(mask)
    else
        mask_padded = reverse(vcat(mask, fill!(BitArray(undef,npad), 0)))
    end
    bits = ntuple(i -> _bitarray2uint64(mask_padded[n*(i-1)+1:n*i]), 16)
    return Ccpu_set_t(reverse(bits))
end
Ccpu_set_t() = Ccpu_set_t(ntuple(i -> zero(UInt64), 16))
function Ccpu_set_t(cpuids::AbstractVector{<:Integer})
    mask = fill!(BitArray(undef,1024), 0)
    for cpuid in cpuids
        mask[cpuid+1] = 1
    end
    return Ccpu_set_t(mask)
end

function _bitarray2uint64(arr)
    length(arr) == 64 || throw(ArgumentError("Input bit array must have length 64."))
    return parse(UInt64, replace(bitstring(arr), " " => ""), base=2)
end

_pthread_self() = @ccall libpthread.pthread_self()::Cpthread_t


# -------------------- SET AFFINITY
function _pthread_setaffinity_np(thread, cpussetsize, cpuset::Ccpu_set_t)
    @ccall libpthread.pthread_setaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t,
                                             cpuset::Ccpu_set_t)::Cint
end
function _pthread_setaffinity_np(thread, cpussetsize, cpuset)
    @ccall libpthread.pthread_setaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t,
                                             cpuset::Ptr{Ccpu_set_t})::Cint
end

"""
The input `mask` should be either of the following:
* a `BitArray` indicating the mask directly
* a vector of cpuids (the mask will be constructed automatically)
"""
pthread_set_affinity_mask(mask) = pthread_set_affinity_mask(threadid(), mask)
function pthread_set_affinity_mask(threadid, mask)
    cpuset = Ccpu_set_t(mask)
    cpuset_ref = Ref{Ccpu_set_t}(cpuset)
    ret = fetch(@tspawnat threadid _pthread_setaffinity_np(_pthread_self(), sizeof(cpuset), cpuset_ref))
    if ret != 0
        @warn "_pthread_setaffinity_np call returned a non-zero value (indicating failure)"
    end
    return nothing
end
pthread_pinthread(cpuid::Integer) = pthread_set_affinity_mask([cpuid])
pthread_pinthread(threadid::Integer, cpuid::Integer) = pthread_set_affinity_mask(threadid, [cpuid])
function pthread_pinthreads(cpuids::AbstractVector{<:Integer})
    ncpuids = length(cpuids)
    @threads :static for tid in 1:ncpuids
        pthread_pinthread(cpuids[tid])
    end
    return nothing
end

# -------------------- GET AFFINITY
function _pthread_getaffinity_np(thread, cpussetsize, cpuset)
    @ccall libpthread.pthread_getaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t,
                                             cpuset::Ptr{Ccpu_set_t})::Cint
end

pthread_get_affinity_mask(; kwargs...) = pthread_get_affinity_mask(threadid(); kwargs...)
function pthread_get_affinity_mask(threadid; convert=true)
    cpuset = Ref{Ccpu_set_t}()
    ret = fetch(@tspawnat threadid _pthread_getaffinity_np(_pthread_self(), sizeof(cpuset), cpuset))
    if ret != 0
        @warn "_pthread_getaffinity_np call returned a non-zero value (indicating failure)"
    end
    return convert ? Base.convert(BitArray, cpuset[]) : cpuset[]
end

pthread_print_affinity_mask(; kwargs...) = pthread_print_affinity_mask(threadid(); kwargs...)
function pthread_print_affinity_mask(threadid; groupby=:sockets)
    mask = Ref{Ccpu_set_t}()
    ret = fetch(@tspawnat threadid _pthread_getaffinity_np(_pthread_self(), sizeof(mask), mask))
    if ret != 0
        @warn "_pthread_getaffinity_np call returned a non-zero value (indicating failure)"
    end
    bitstr = reverse(join(bitstring.(reverse(mask[].bits))))[1:ncputhreads()]
    if groupby == :numa
        cpuids_per_X = cpuids_per_numa
        nX = nnuma
    else
        cpuids_per_X = cpuids_per_socket
        nX = nsockets
    end
    print("|")
    for s in 1:nX()
        print(bitstr[cpuids_per_X()[s].+1],"|")
    end
    print("\n")
    return nothing
end
function pthread_print_affinity_masks(; kwargs...)
    for i in 1:nthreads()
        pthread_print_affinity_mask(i; kwargs...)
    end
    return nothing
end

function pthread_getcpuid(threadid=Threads.threadid())
    mask = pthread_get_affinity_mask(threadid)
    if count(mask) == 1 # exactly one bit set
        return findfirst(mask)-1
    else
        @warn "The affinity mask of Julia thread $threadid includes multiple cpu threads."
        return -1
    end
end
