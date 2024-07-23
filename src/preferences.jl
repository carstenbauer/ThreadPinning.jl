module Prefs

using Preferences: @has_preference, @load_preference, @set_preferences!, @delete_preferences!
using DocStringExtensions: SIGNATURES
using ..ThreadPinning: getstdout

const ALL_PREFERENCES = ("autoupdate", "pin", "likwidpin", "os_warning")

"Query whether the pin preference is set"
has_pin() = @has_preference("pin")
"Query whether the likwidpin preference is set"
has_likwidpin() = @has_preference("likwidpin")

"Get the pin preference. Returns `nothing` if not set."
function get_pin()
    p = @load_preference("pin")
    # TODO check if valid?
    return p
end
"Get the likwidpin preference. Returns `nothing` if not set."
function get_likwidpin()
    p = @load_preference("likwidpin")
    # TODO check if valid?
    return p
end

"$(SIGNATURES)Set the pin preference"
function set_pin(s::Union{Symbol, AbstractString})
    # TODO check if valid?
    @set_preferences!("pin"=>String(s))
    return
end
"$(SIGNATURES)Set the likwidpin preference"
function set_likwidpin(s::AbstractString)
    # TODO check if valid?
    @set_preferences!("likwidpin"=>s)
    return
end

"Clear all ThreadPinning.jl related preferences"
function clear()
    @delete_preferences!(ALL_PREFERENCES...)
end

"Show all ThreadPinning.jl related preferences"
function showall(io = getstdout())
    for pref in ALL_PREFERENCES
        val = @load_preference(pref)
        println(io, "$pref => $val")
    end
    return
end

"Query whether the autoupdate preference is set"
has_autoupdate() = @has_preference("autoupdate")

"Get the autoupdate preference. Returns `nothing` if not set."
function get_autoupdate()
    p = @load_preference("autoupdate")
    if isnothing(p)
        return #default
    else
        try
            b = parse(Bool, lowercase(p))
            return b
        catch
            throw(ArgumentError("`$p` is not a valid value for the autoupdate preference"))
        end
    end
end

"$(SIGNATURES)Set the autoupdate preference"
function set_autoupdate(b::Bool)
    @set_preferences!("autoupdate"=>string(b))
    @info("Done. Package might recompile next time it is loaded (in a new Julia session).")
    return
end

"Query whether the OS warning preference is set"
has_os_warning() = @has_preference("os_warning")

"Get the OS warning preference. Returns `nothing` if not set."
function get_os_warning()
    p = @load_preference("os_warning")
    if isnothing(p)
        return #default
    else
        try
            b = parse(Bool, lowercase(p))
            return b
        catch
            throw(ArgumentError("`$p` is not a valid value for the OS warning preference"))
        end
    end
end

"$(SIGNATURES)Set the OS warning preference"
function set_os_warning(b::Bool)
    @set_preferences!("os_warning"=>string(b))
    @info("Done. Package might recompile next time it is loaded (in a new Julia session).")
    return
end

end # module
