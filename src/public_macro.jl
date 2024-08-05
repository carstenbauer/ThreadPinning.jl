_valid_macro(expr) = Meta.isexpr(expr, :macrocall) && length(expr.args) == 2 &&
    expr.args[1] isa Symbol && string(expr.args[1])[1] == '@' &&
    expr.args[2] isa LineNumberNode

_get_symbols(symbol::Symbol) = [symbol]
function _get_symbols(expr::Expr)
    _valid_macro(expr) && return [expr.args[1]]
    expr.head == :tuple || throw(ArgumentError("cannot mark `$expr` as public. Try `@compat public foo, bar`."))
    symbols = Vector{Symbol}(undef, length(expr.args))
    for (i, arg) in enumerate(expr.args)
        if arg isa Symbol
            symbols[i] = arg
        elseif _valid_macro(arg)
            symbols[i] = arg.args[1]
        else
            throw(ArgumentError("cannot mark `$arg` as public. Try `@compat public foo, bar`."))
        end
    end
    symbols
end

macro public(symbols_expr::Union{Expr, Symbol})
    symbols = _get_symbols(symbols_expr)
    if VERSION >= v"1.11.0-DEV.469"
        esc(Expr(:public, symbols...))
    end
end
