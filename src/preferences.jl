module Prefs

using Preferences

const ALL_PREFERENCES = ("autoupdate",)

# "Query whether the pinning strategy preference is set"
# function has_pinning()
#     @has_preference("pinning")
# end

# "Get the pinning strategy. Returns `nothing` if not set."
# function get_pinning()
#     p = @load_preference("pinning")
#     if isnothing(p)
#         return nothing
#     else
#         s = Symbol(p)
#         if !is_valid_pinning_symbol(s)
#             error("`$s` is not a valid pinning strategy preference")
#         else
#             return s
#         end
#     end
# end

# "Set the pinning strategy preference"
# function set_pinning(s::Symbol)
#     if !is_valid_pinning_symbol(s)
#         throw(ArgumentError("`$s` is not a valid pinning strategy"))
#     end
#     @set_preferences!("pinning"=>String(s))
#     return nothing
# end

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
function has_autoupdate()
    @has_preference("autoupdate")
end

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

"Set the autoupdate preference"
function set_autoupdate(b::Bool)
    @set_preferences!("autoupdate"=>string(b))
    @info("Done. Package might recompile next time it is loaded (in a new Julia session).")
    return nothing
end

end # module
