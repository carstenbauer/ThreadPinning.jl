"""
Check if MKL library (`libmkl_rt`) is available in `Libdl.dllist()` (as is the case when
loading [MKL.jl](https://github.com/JuliaLinearAlgebra/MKL.jl) or
[MKL_jll.jl](https://github.com/JuliaBinaryWrappers/MKL_jll.jl)).
"""
function mkl_is_available()
    any(endswith(lib, "libmkl_rt.$(Libdl.dlext)") for lib in Libdl.dllist())
end

"""
Check whether Intel MKL is currently loaded (via libblastrampoline).
"""
function mkl_is_loaded()
    @static if VERSION <= v"1.7-"
        mkl_is_available()
    else
        any(x -> startswith(x, "libmkl_rt"),
            basename(lib.libname) for lib in BLAS.get_config().loaded_libs)
    end
end

"""
    mkl_get_dynamic()
Wrapper around the MKL function [`mkl_get_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-fortran/top/support-functions/threading-control/mkl-get-dynamic.html).
"""
mkl_get_dynamic() = @ccall dlpath("libmkl_rt").mkl_get_dynamic()::Cint

"""
    mkl_set_dynamic(flag::Integer)
Wrapper around the MKL function [`mkl_set_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-c/top/support-functions/threading-control/mkl-set-dynamic.html).
"""
function mkl_set_dynamic(flag::Integer)
    @ccall dlpath("libmkl_rt").MKL_Set_Dynamic(flag::Cint)::Cvoid
end
