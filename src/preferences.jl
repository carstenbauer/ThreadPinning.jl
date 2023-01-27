module Prefs

using Preferences
using DocStringExtensions

const ALL_PREFERENCES = ("autoupdate", "pin", "likwidpin")

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
    return nothing
end
"$(SIGNATURES)Set the likwidpin preference"
function set_likwidpin(s::AbstractString)
    # TODO check if valid?
    @set_preferences!("likwidpin"=>s)
    return nothing
end

"Clear all ThreadPinning.jl related preferences"
function clear()
    @delete_preferences!(ALL_PREFERENCES...)
end

"Show all ThreadPinning.jl related preferences"
function showall()
    for pref in ALL_PREFERENCES
        val = @load_preference(pref)
        println("$pref => $val")
    end
    return nothing
end

"Query whether the autoupdate preference is set"
has_autoupdate() = @has_preference("autoupdate")

"Get the autoupdate preference. Returns `nothing` if not set."
function get_autoupdate()
    p = @load_preference("autoupdate")
    if isnothing(p)
        return nothing #default
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
    return nothing
end

end # module
