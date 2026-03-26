module MKL

using LinearAlgebra: LinearAlgebra, BLAS
using Libdl: Libdl

const MKL_PATH = Ref{Union{Nothing, String}}(nothing)
const MKL_HANDLE = Ref{Ptr{Cvoid}}(C_NULL)

"""
Returns the full path to the `libmkl_rt` library if the latter is loaded. Will try to
locate the library and, if successfull, will cache the result. Throws an error otherwise.

To force an update of the cache, provide `force_update=true`.
"""
function mkl_fullpath(; force_update = false)
    if isnothing(MKL_PATH[])
        # First-time lookup: just cache the path
        mklpath = _find_mkl()
        MKL_PATH[] = mklpath
    elseif force_update
        # Force a re-discovery of the path
        mklpath = _find_mkl()
        if MKL_PATH[] != mklpath
            # Path changed: close any existing handle and invalidate cache
            if MKL_HANDLE[] != C_NULL
                Libdl.dlclose(MKL_HANDLE[])
            end
            MKL_HANDLE[] = C_NULL
            MKL_PATH[] = mklpath
        end
    end
    return MKL_PATH[]
end

function _mkl_handle()
    if MKL_HANDLE[] == C_NULL
        MKL_HANDLE[] = Libdl.dlopen(mkl_fullpath())
    end
    return MKL_HANDLE[]
end

"""
Check whether Intel MKL is currently loaded via libblastrampoline
"""
function mkl_is_loaded()
    any(x -> startswith(x, "libmkl_rt"),
        basename(lib.libname) for lib in BLAS.get_config().loaded_libs)
end

# locate libmkl_rt (i.e. full path to it)
function _find_mkl()
    mklidx = findfirst(lib -> startswith(basename(lib.libname), "libmkl_rt"),
        BLAS.get_config().loaded_libs)
    if isnothing(mklidx)
        error("Intel MKL not loaded via LBT.")
    end
    fullpath = BLAS.get_config().loaded_libs[mklidx].libname
    return fullpath
end

"""
    mkl_get_dynamic()
Wrapper around the MKL function [`mkl_get_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-fortran/top/support-functions/threading-control/mkl-get-dynamic.html).
"""
mkl_get_dynamic() = ccall(Libdl.dlsym(_mkl_handle(), :mkl_get_dynamic), Cint, ())

"""
    mkl_set_dynamic(flag::Integer)

Wrapper around the MKL function [`mkl_set_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-c/top/support-functions/threading-control/mkl-set-dynamic.html).
"""
function mkl_set_dynamic(flag::Integer)
    ccall(Libdl.dlsym(_mkl_handle(), :MKL_Set_Dynamic), Cvoid, (Cint,), flag)
end

end # module
