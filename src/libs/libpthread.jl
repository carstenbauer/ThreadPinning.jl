# ------------ pthread.h ------------
const libpthread = "libpthread"

const Cpthread_t = Culong
const Ccpu_set_t_tuple = NTuple{16, UInt64}
struct Ccpu_set_t
    bits::NTuple{16, UInt64}
end
function Base.convert(::Type{BitArray}, cpuset)
    # TODO: improve
    bitstr = join(bitstring.(reverse(cpuset.bits)))
    maskarray = BitArray(b == '0' ? false : true for b in bitstr[end-ncputhreads()+1:end])
    return maskarray
end
Base.show(io::IO, cpuset::Ccpu_set_t) = print(io, "Ccpu_set_t(", join(bitstring.(reverse(cpuset.bits))),")")

_pthread_self() = @ccall libpthread.pthread_self()::Cpthread_t

# pthread_setaffinity_np
function _pthread_setaffinity_np(thread, cpussetsize, cpuset::Ccpu_set_t_tuple)
    @ccall libpthread.pthread_setaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t,
                                             cpuset::Ccpu_set_t_tuple)::Cint
end
function _pthread_setaffinity_np(thread, cpussetsize, cpuset::Ccpu_set_t)
    @ccall libpthread.pthread_setaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t,
                                             cpuset::Ccpu_set_t)::Cint
end

# pthread_getaffinity_np
function _pthread_getaffinity_np(thread, cpussetsize, cpuset)
    @ccall libpthread.pthread_getaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t,
                                             cpuset::Ptr{Ccpu_set_t})::Cint
end

function pthread_get_affinity_mask(threadid)
    cpuset = Ref{Ccpu_set_t}()
    ret = fetch(@tspawnat threadid _pthread_getaffinity_np(_pthread_self(), sizeof(cpuset), cpuset))
    if ret != 0
        @warn "_pthread_getaffinity_np call returned a non-zero value (indicating failure)"
    end
    return convert(BitArray, cpuset[])
end

function pthread_print_affinity_mask(threadid)
    mask = Ref{Ccpu_set_t}()
    ret = fetch(@tspawnat threadid _pthread_getaffinity_np(_pthread_self(), sizeof(mask), mask))
    if ret != 0
        @warn "_pthread_getaffinity_np call returned a non-zero value (indicating failure)"
    end
    println(join(bitstring.(reverse(mask[].bits)))[end-ncputhreads()+1:end])
    return nothing
end

function pthread_getcpuid(threadid=Threads.threadid())
    mask = pthread_get_affinity_mask(threadid)
    if count(mask) == 1 # exactly one bit set
        return findfirst(reverse(mask))-1
    else
        @warn "The affinity mask of Julia thread $threadid includes multiple cpu threads."
        return -1
    end
end
