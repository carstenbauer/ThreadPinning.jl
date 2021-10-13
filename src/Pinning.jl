module Pinning

using Libdl

# helper
function grabfromthreads(fn)
    T = typeof(fn())
    values = zeros(T, Threads.nthreads())
    Threads.@threads :static for i in 1:Threads.nthreads()
        values[i] = fn()
    end
    d = Dict{Int64, T}(zip(1:Threads.nthreads(), values))
    return d
end

get_processor_id() = Int(@ccall sched_getcpu()::Cint)

get_processor_id()

grabfromthreads(get_processor_id)

# ------------ pthread.h ------------
const pthread = Libdl.find_library("libpthread")
# Justification: https://refspecs.linuxfoundation.org/LSB_3.1.0/LSB-Core-generic/LSB-Core-generic/libpthread-ddefs.html
const Cpthread_t = Culong

# ?!?!
const __ULONG32_TYPE = Culong
const __t_uscalar_t = __ULONG32_TYPE
const __ULONGWORD_TYPE = __t_uscalar_t
const __CPU_MASK_TYPE = __ULONGWORD_TYPE
const __cpu_mask = __CPU_MASK_TYPE

const __CPU_SETSIZE	= 1024
const __NCPUBITS = (8 * sizeof(__cpu_mask))

"Data structure to describe CPU mask.

https://github.com/lattera/glibc/blob/master/posix/bits/cpu-set.h
"
struct Ccpu_set_t
  __bits::Vector{__cpu_mask} 
  Ccpu_set_t() = new(zeros(__cpu_mask, Int(__CPU_SETSIZE / __NCPUBITS)))
end

"""
Returns the ID of the calling thread.
This is the same value that is returned in `*thread` in the
`pthread_create(3)`` call that created this thread.

https://man7.org/linux/man-pages/man3/pthread_self.3.html
"""
pthread_self() = @ccall pthread.pthread_self()::Cpthread_t

pthread_self()
pthread_self() |> Int

"""
https://man7.org/linux/man-pages/man3/pthread_setaffinity_np.3.html
"""
function pthread_setaffinity_np end
# int pthread_setaffinity_np(pthread_t thread, size_t cpusetsize,
#                             const cpu_set_t *cpuset);
# int pthread_getaffinity_np(pthread_t thread, size_t cpusetsize,
#                             cpu_set_t *cpuset);

pthread_setaffinity_np(thread, cpussetsize, cpuset) =
    @ccall pthread.pthread_setaffinity_np(thread::Cpthread_t, cpussetsize::Csize_t, cpuset::Ptr{Ccpu_set_t})::Cint

function pinthread(processorId::Integer)
    cpuset = Ccpu_set_t()
    cpuset_ref = Ref(cpuset)
    thread = zero(pthread_t)

    thread = pthread_self()
    # CPU_ZERO(&cpuset)
    # CPU_SET(processorId, &cpuset);
    pthread_setaffinity_np(thread, sizeof(Ccpu_set_t), cpuset_ref)
end

pinthread(1)

grabfromthreads(get_processor_id)


# ------------ sched.h ------------
"""
https://man7.org/linux/man-pages/man2/sched_setaffinity.2.html
"""
sched_getaffinity(pid::Integer) = @ccall sched_getaffinity(pid::Cint)::Cint
# int sched_getaffinity(pid_t pid, size_t cpusetsize,
#                         cpu_set_t *mask);

# sched_getaffinity(getpid())


# ------------ unistd.h ------------
# Justification: "In the GNU C Library, this is an int."
# from http://www.gnu.org/software/libc/manual/html_node/Process-Identification.html
const pid_t = Cint

"""
Returns the process ID (PID) of the calling process.
https://man7.org/linux/man-pages/man2/getpid.2.html
"""
getpid() = @ccall getpid()::pid_t
"""
Returns the process ID of the parent of the calling process.
https://man7.org/linux/man-pages/man2/getpid.2.html
"""
getppid() = @ccall getppid()::pid_t

getpid()
getppid()

grabfromthreads(getpid)
grabfromthreads(getppid)

"""
Returns the caller's thread ID (TID).  In a single-
threaded process, the thread ID is equal to the process ID (PID,
as returned by `getpid(2)`).  In a multithreaded process, all
threads have the same PID, but each one has a unique TID.

https://man7.org/linux/man-pages/man2/gettid.2.html
"""
gettid() = @ccall gettid()::pid_t

grabfromthreads(gettid)

end
