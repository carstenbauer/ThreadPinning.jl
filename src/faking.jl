module Faking

import SysInfo
import ThreadPinningCore

const ISFAKING = Ref(false)

isfaking() = ISFAKING[]

function start(name::AbstractString; kwargs...)
    isfaking() && stop() # to be safe
    ts = SysInfo.TestSystems.load(name)
    SysInfo.TestSystems.use(ts; kwargs...)
    ThreadPinningCore.Internals.enable_faking(SysInfo.cpuids())
    ISFAKING[] = true
    return
end

function stop()
    SysInfo.TestSystems.reset()
    ThreadPinningCore.Internals.disable_faking()
    ISFAKING[] = false
    return
end

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
