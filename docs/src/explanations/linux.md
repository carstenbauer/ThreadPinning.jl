# [Why is Only Linux Supported?](@id linux)

For ThreadPinning.jl to fully work, the operating system must support querying and setting the affinity of Julia threads (pthreads). This is readily possible on Linux but less so or more complicated on Windows and macOS. See below for more information.

## Linux

We use `libc`s [`sched_getcpu`](https://man7.org/linux/man-pages/man3/sched_getcpu.3.html) to query the ID of the CPU-Thread that is currently running a given Julia thread. For pinning, we use [`uv_thread_setaffinity`](https://github.com/clibs/uv/blob/master/docs/src/threading.rst) provided by `libuv`. For the corresponding Julia wrappers of these libraries, see SysInfo.jl and ThreadPinningCore.jl.

## Windows

I neither have much knowledge about Windows APIs nor proper access to Windows machines. Nonetheless, I've made an initial attempt to add partial Windows support in [this PR](https://github.com/carstenbauer/ThreadPinning.jl/pull/29). If you're eager to have Windows fully supported, please take matters into your own hand. I'm happy to offer help and review a PR from you.

## macOS

Unfortunately, macOS doesn't support any way to pin threads to specific CPU-threads. It is thus very unlikely that macOS can ever be fully supported.

Having said that, there seems to be a (very?) limited [Thread Affinity API](https://developer.apple.com/library/archive/releasenotes/Performance/RN-AffinityAPI/#//apple_ref/doc/uid/TP40006635-CH1-DontLinkElementID_2) for which support might be added. This is unlikely to ever be on my agenda though.