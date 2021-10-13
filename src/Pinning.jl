module Pinning

using Base.Threads: @threads, nthreads

include("helper.jl")
include("libc.jl")
include("libuv.jl")
include("libpthread.jl")
include("api.jl")
export getcpuid, getcpuids, pinthread, pinthreads

end
