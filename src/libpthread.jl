# ------------ pthread.h ------------
const libpthread = "libpthread"
# Justification: https://refspecs.linuxfoundation.org/LSB_3.1.0/LSB-Core-generic/LSB-Core-generic/libpthread-ddefs.html
const pthread_t = Culong

const __ULONG32_TYPE = Culong
const __t_uscalar_t = __ULONG32_TYPE
const __ULONGWORD_TYPE = __t_uscalar_t
const __CPU_MASK_TYPE = __ULONGWORD_TYPE
const __cpu_mask = __CPU_MASK_TYPE

const __CPU_SETSIZE = 1024
const __NCPUBITS = (8 * sizeof(__cpu_mask))

"Data structure to describe CPU mask.

https://github.com/lattera/glibc/blob/master/posix/bits/cpu-set.h
"
struct cpu_set_t
    __bits::NTuple{16,__cpu_mask}
end

"""
Returns the ID of the calling thread.
This is the same value that is returned in `*thread` in the
`pthread_create(3)`` call that created this thread.

https://man7.org/linux/man-pages/man3/pthread_self.3.html
"""
pthread_self() = @ccall libpthread.pthread_self()::pthread_t

"""
https://man7.org/linux/man-pages/man3/pthread_setaffinity_np.3.html
"""
function pthread_setaffinity_np end

pthread_setaffinity_np(thread, cpussetsize, cpuset) =
    @ccall libpthread.pthread_setaffinity_np(thread::pthread_t, cpussetsize::Csize_t, cpuset::Ptr{cpu_set_t})::Cint

# function pinthread(processorId::Integer)
#     cpuset = cpu_set_t()
#     cpuset_ref = Ref(cpuset)
#     thread = zero(pthread_t)

#     thread = pthread_self()
#     # CPU_ZERO(&cpuset)
#     # CPU_SET(processorId, &cpuset);
#     pthread_setaffinity_np(thread, sizeof(cpu_set_t), cpuset_ref)
# end