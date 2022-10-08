module Prefs

using Preferences
using ..ThreadPinning: is_valid_pinning_symbol, is_valid_places_symbol

_nothing_or_symbol(x) = Symbol(x)
_nothing_or_symbol(x::Nothing) = nothing

const ALL_PREFERENCES = ("pinning", "places", "autoupdate")

function has_pinning()
    @has_preference("pinning")
end

function get_pinning()
    p = @load_preference("pinning")
    if isnothing(p)
        return nothing
    else
        s = Symbol(p)
        if !is_valid_pinning_symbol(s)
            error("`$s` is not a valid pinning strategy preference")
        else
            return s
        end
    end
end

function set_pinning(s::Symbol)
    if !is_valid_pinning_symbol(s)
        throw(ArgumentError("`$s` is not a valid pinning strategy"))
    end
    @set_preferences!("pinning"=>String(s))
    return nothing
end

function has_places()
    @has_preference("places")
end

function get_places()
    p = @load_preference("places")
    if isnothing(p)
        return nothing
    else
        s = Symbol(p)
        if !is_valid_places_symbol(s)
            error("`$s` is not a valid places preference")
        else
            return s
        end
    end
end

function set_places(s::Symbol)
    if !is_valid_places_symbol(s)
        throw(ArgumentError("`$s` is not a valid places symbol"))
    end
    @set_preferences!("places"=>String(s))
    return nothing
end

function has_autoupdate()
    @has_preference("autoupdate")
end

function get_autoupdate()
    p = @load_preference("autoupdate")
    if isnothing(p)
        return nothing
    else
        try
            return parse(Bool, lowercase(p))
        catch err
            error("`$p` is not a valid autoupdate preference")
        end
    end
end

function set_autoupdate(b::Bool)
    @set_preferences!("autoupdate"=>string(b))
    return nothing
end

function clear()
    @delete_preferences!(ALL_PREFERENCES...)
end

end # module
