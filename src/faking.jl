module Faking

import SysInfo
import ThreadPinningCore

const ISFAKING = Ref(false)

"Are we currently in fake mode?"
isfaking() = ISFAKING[]

"""
    start(system_name)

Start faking being on the given system.
"""
function start(name::AbstractString; kwargs...)
    isfaking() && stop() # to be safe
    ts = SysInfo.TestSystems.load(name)
    SysInfo.TestSystems.use(ts; kwargs...)
    ThreadPinningCore.Internals.enable_faking(SysInfo.cpuids())
    ISFAKING[] = true
    return
end

"""
    stop()

Stop faking.
"""
function stop()
    SysInfo.TestSystems.reset()
    ThreadPinningCore.Internals.disable_faking()
    ISFAKING[] = false
    return
end

"""
    with(f, system_name)

Fake running `f` on the given system.

**Example**
```julia
with("PerlmutterComputeNode") do
    threadinfo()
end
```
"""
function with(f::F, name::AbstractString) where {F}
    start(name)
    try
        return f()
    finally
        stop()
    end
end

systems() = SysInfo.TestSystems.list()

end # module
