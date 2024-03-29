"""
Check whether Intel MKL is currently loaded via libblastrampoline (Julia >= 1.7)
or is available in `Libdl.dllist()` (Julia 1.6).
"""
function mkl_is_loaded()
    @static if VERSION <= v"1.7-"
        any(endswith(lib, "libmkl_rt.$(Libdl.dlext)") for lib in Libdl.dllist())
    else
        any(x -> startswith(x, "libmkl_rt"),
            basename(lib.libname) for lib in BLAS.get_config().loaded_libs)
    end
end

"""
$(SIGNATURES)
Returns the full path to the `libmkl_rt` library if the latter is loaded. Will try to
locate the library and, if successfull, will cache the result. Throws an error otherwise.

To force an update of the cache, provide `force_update=true`.
"""
function mkl_fullpath(; force_update = false)
    if isnothing(MKL_PATH[]) || force_update
        mklpath = _find_mkl()
        MKL_PATH[] = mklpath
    end
    return MKL_PATH[]
end

# locate libmkl_rt (i.e. full path to it)
function _find_mkl()
    @static if VERSION <= v"1.7-"
        mklidx = findfirst(lib -> endswith(lib, "libmkl_rt.$(Libdl.dlext)"), Libdl.dllist())
        if isnothing(mklidx)
            error("Intel MKL not loaded.")
        end
        fullpath = Libdl.dllist()[mklidx]
    else
        mklidx = findfirst(lib -> startswith(basename(lib.libname), "libmkl_rt"),
                           BLAS.get_config().loaded_libs)
        if isnothing(mklidx)
            error("Intel MKL not loaded via LBT.")
        end
        fullpath = BLAS.get_config().loaded_libs[mklidx].libname
    end
    return fullpath
end

"""
    mkl_get_dynamic()
Wrapper around the MKL function [`mkl_get_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-fortran/top/support-functions/threading-control/mkl-get-dynamic.html).
"""
mkl_get_dynamic() = @ccall mkl_fullpath().mkl_get_dynamic()::Cint

"""
$(SIGNATURES)
Wrapper around the MKL function [`mkl_set_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-c/top/support-functions/threading-control/mkl-set-dynamic.html).
"""
function mkl_set_dynamic(flag::Integer)
    @ccall mkl_fullpath().MKL_Set_Dynamic(flag::Cint)::Cvoid
end

const MKL_PATH = Ref{Union{Nothing, String}}(nothing)
