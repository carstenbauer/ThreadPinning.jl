# ------------ unistd.h ------------
# Justification: "In the GNU C Library, this is an int."
# from http://www.gnu.org/software/libc/manual/html_node/Process-Identification.html
const pid_t = Cint

"""
Returns the process ID (PID) of the calling process.

Ref: [docs](https://man7.org/linux/man-pages/man2/getpid.2.html)
"""
getpid() = @ccall getpid()::pid_t
"""
Returns the process ID of the parent of the calling process.

Ref: [docs](https://man7.org/linux/man-pages/man2/getpid.2.html)
"""
getppid() = @ccall getppid()::pid_t

"""
Returns the caller's thread ID (TID).  In a single-
threaded process, the thread ID is equal to the process ID (PID,
as returned by `getpid(2)`).  In a multithreaded process, all
threads have the same PID, but each one has a unique TID.

Ref: [docs](https://man7.org/linux/man-pages/man2/gettid.2.html)
"""
gettid() = @ccall gettid()::pid_t

# ------------ sched.h ------------
"""
Returns the number of the CPU on which the calling thread
is currently executing.

Ref: [docs](https://man7.org/linux/man-pages/man3/sched_getcpu.3.html)
"""
sched_getcpu() = @ccall sched_getcpu()::Cint

# """
# https://man7.org/linux/man-pages/man2/sched_setaffinity.2.html
# """
# sched_getaffinity(pid::Integer) = @ccall sched_getaffinity(pid::Cint)::Cint
# int sched_getaffinity(pid_t pid, size_t cpusetsize,
#                         cpu_set_t *mask);

# sched_getaffinity(getpid())