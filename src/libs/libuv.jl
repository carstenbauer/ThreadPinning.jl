# ------------ uv.h ------------
# Documentation:
# https://github.com/clibs/uv/blob/master/docs/src/threading.rst
const uv_thread_t = Culong # = pthread_t

"""
Returns the maximum size of the mask used for process/thread affinities,
or `UV_ENOTSUP` if affinities are not supported on the current platform.

Ref: [docs](https://github.com/clibs/uv/blob/d0240ce496fcd86d45e8a6b211732220fdb27eac/docs/src/misc.rst#L285)
"""
uv_cpumask_size() = @ccall uv_cpumask_size()::Cint

"""
Ref: [docs](https://github.com/clibs/uv/blob/d0240ce496fcd86d45e8a6b211732220fdb27eac/docs/src/threading.rst#L130)
"""
uv_thread_self() = @ccall uv_thread_self()::uv_thread_t

"""
    uv_thread_getaffinity(self_ref, cpumask, masksize)
Gets the specified thread's affinity setting. On Unix, this maps the
`cpu_set_t` returned by `pthread_getaffinity_np(3)` to bytes in `cpumask`.

The `masksize` specifies the number of entries (bytes) in `cpumask`,
and must be greater-than-or-equal-to `uv_cpumask_size`.

**Note:** Thread affinity getting is not atomic on Windows and unsupported on macOS.

Ref: [docs](https://github.com/clibs/uv/blob/master/docs/src/threading.rst)
"""
function uv_thread_getaffinity(self_ref, cpumask, masksize)
    @ccall uv_thread_getaffinity(self_ref::Ptr{uv_thread_t}, cpumask::Ptr{Cchar},
                                 masksize::Cssize_t)::Cint
end

"""
    uv_thread_getaffinity()
Query the calling thread's affinity.
"""
function uv_thread_getaffinity()
    # inspired by https://github.com/JuliaLang/julia/pull/42340
    masksize = uv_cpumask_size()
    self = uv_thread_self()
    self_ref = Ref(self)
    cpumask = zeros(Cchar, masksize)
    err = uv_thread_getaffinity(self_ref, cpumask, masksize)
    @assert err == 0
    n = findlast(isone, cpumask)
    resize!(cpumask, n)
    return cpumask
end

"""
    uv_thread_setaffinity(self_ref, cpumask, oldmask, masksize)
Sets the specified thread's affinity to `cpumask`, which is specified in
bytes. Optionally returning the previous affinity setting in `oldmask`.
On Unix, uses `pthread_getaffinity_np(3)` to get the affinity setting
and maps the `cpu_set_t` to bytes in `oldmask`. Then maps the bytes in `cpumask`
to a `cpu_set_t` and uses `pthread_setaffinity_np(3)`. On Windows, maps
the bytes in `cpumask` to a bitmask and uses `SetThreadAffinityMask()` which
returns the previous affinity setting.

The `masksize` specifies the number of entries (bytes) in `cpumask / oldmask`,
and must be greater-than-or-equal-to `uv_cpumask_size()`.

**Note:** Thread affinity setting is not atomic on Windows and unsupported on macOS.

Ref: [docs](https://github.com/clibs/uv/blob/master/docs/src/threading.rst)
"""
function uv_thread_setaffinity(self_ref, cpumask, oldmask, masksize)
    @ccall uv_thread_setaffinity(self_ref::Ptr{uv_thread_t},
                                 cpumask::Ptr{Cchar},
                                 oldmask::Ptr{Cchar},
                                 masksize::Csize_t)::Cint
end

"""
    uv_thread_setaffinity(procid::Integer) 
Set the calling thread's affinity to `procid`.
"""
function uv_thread_setaffinity(procid::Integer)
    masksize = uv_cpumask_size()
    0 ≤ procid ≤ masksize ||
        throw(ArgumentError("Invalid procid. It must hold 0 ≤ procid ≤ masksize."))
    self = uv_thread_self()
    self_ref = Ref(self)
    cpumask = zeros(Cchar, masksize)
    cpumask[procid + 1] = 1
    err = uv_thread_setaffinity(self_ref, cpumask, C_NULL, masksize)
    return err == 0
end
