# [How It Works](@id how)

We use libc's [`sched_getcpu`](https://man7.org/linux/man-pages/man3/sched_getcpu.3.html) to query the CPU-core ID for a thread and libuv's [`uv_thread_setaffinity`](https://github.com/clibs/uv/blob/master/docs/src/threading.rst) to set the affinity of a thread. For the corresponding Julia wrappers, see [LibX](@ref).