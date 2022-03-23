"""
Print information about Julia threads, e.g. on which cpu threads (i.e. cores if hyperthreading is disabled) they are running.

Keyword arguments:
* `color` (default: `true`): Toggle between colored and black-and-white output.
* `blocksize` (default: `32`): Wrap to a new line after `blocksize` many cpu threads.
* `hyperthreading` (default: `true`): If `true`, we (try to) highlight cpu threads associated with hyperthreading in the `color=true` output.
* `blas` (default: `false`): Show information about BLAS threads as well.
* `hints` (default: `false`): Give some hints about how to improve the threading related settings.
* `groupby` (default: `:sockets`): Options are `:sockets`, `:numa`, or `:none`.
"""
function threadinfo(; blas=false, hints=false, color=true, kwargs...)
    maybe_gather_sysinfo()
    # general info
    jlthreads = Threads.nthreads()
    thread_cpuids = getcpuids()
    occupied_cputhreads = length(unique(thread_cpuids))
    cputhreads = Sys.CPU_THREADS
    # visualize current pinning
    println()
    _visualize_affinity(; thread_cpuids, color, kwargs...)
    print("Julia threads: ")
    if color
        printstyled(jlthreads, "\n"; color=jlthreads > cputhreads ? :red : :green)
    else
        printstyled(jlthreads, jlthreads > cputhreads ? "(!)" : "", "\n")
    end
    print("├ Occupied CPU-threads: ")
    if color
        printstyled(
            occupied_cputhreads, "\n"; color=occupied_cputhreads < jlthreads ? :red : :green
        )
    else
        printstyled(occupied_cputhreads, occupied_cputhreads < jlthreads ? "(!)" : "", "\n")
    end
    print("└ Mapping (Thread => CPUID):")
    # print("   ")
    for (tid, core) in pairs(thread_cpuids)
        print(" $tid => $core,")
        if tid == 5
            print(" ...")
            break
        end
    end
    println("\n")
    if blas
        libblas = BLAS_lib()
        println("BLAS: ", libblas)
        if contains(libblas, "openblas")
            print("└ openblas_get_num_threads: ")
            if color
                printstyled(
                    BLAS.get_num_threads(), "\n"; color=_color_openblas_num_threads()
                )
            else
                printstyled(
                    BLAS.get_num_threads(),
                    _color_openblas_num_threads() == :red ? "(!)" : "",
                    "\n",
                )
            end
            println()
            _color_openblas_num_threads(; hints)
        elseif contains(libblas, "mkl")
            print("├ mkl_get_num_threads: ")
            if color
                printstyled(BLAS.get_num_threads(), "\n"; color=_color_mkl_num_threads())
            else
                printstyled(
                    BLAS.get_num_threads(),
                    _color_mkl_num_threads() == :red ? "(!)" : "",
                    "\n",
                )
            end
            println("└ mkl_get_dynamic: ", Bool(mkl_get_dynamic()))
            println()
            _color_mkl_num_threads(; hints)
        end
    end
    hints && _general_hints()
    return nothing
end

function _visualize_affinity(;
    thread_cpuids=getcpuids(),
    blocksize=16,
    color=true,
    groupby=:sockets,
    hyperthreading=hyperthreading_is_enabled(),
)
    ncpuids = Sys.CPU_THREADS
    cpuids_grouped = if groupby in (:sockets, :socket)
        cpuids_per_socket()
    elseif groupby == :numa
        cpuids_per_numa()
    else
        [collect(0:(Sys.CPU_THREADS - 1))]
    end
    printstyled("| "; bold=true)
    for (i, cpuids) in pairs(cpuids_grouped)
        for (k, cpuid) in pairs(cpuids)
            if color
                if cpuid in thread_cpuids
                    printstyled(
                        cpuid;
                        bold=true,
                        color=if (hyperthreading && ishyperthread(cpuid))
                            :light_magenta
                        else
                            :yellow
                        end,
                    )
                else
                    printstyled(
                        cpuid; color=if (hyperthreading && ishyperthread(cpuid))
                            :light_black
                        else
                            :default
                        end
                    )
                end
            else
                if cpuid in thread_cpuids
                    printstyled(cpuid; bold=true)
                else
                    print("_")
                end
            end
            if !(cpuid == last(cpuids))
                print(",")
                mod(k, blocksize) == 0 && print("\n  ")
            end
        end
        # print(" | ")
        if ncpuids > 32
            printstyled(" |"; bold=true)
            if !(i == length(cpuids_grouped))
                println()
                printstyled("| "; bold=true)
            end
        else
            printstyled(" | "; bold=true)
        end
    end
    println()
    # legend
    println()
    if color
        printstyled("#"; bold=true, color=:yellow)
    else
        printstyled("#"; bold=true)
    end
    print(" = Julia thread, ")
    if hyperthreading
        printstyled("#"; color=:light_black)
        print(" = HT, ")
        printstyled("#"; bold=true, color=:light_magenta)
        print(" = Julia thread on HT, ")
    end
    if groupby in (:sockets, :socket)
        printstyled("|"; bold=true)
        print(" = Socket seperator")
    elseif groupby == :numa
        printstyled("|"; bold=true)
        print(" = NUMA seperator")
    end
    println("\n")
    return nothing
end

function _color_mkl_num_threads(; hints=false)
    jlthreads = Threads.nthreads()
    cputhreads = Sys.CPU_THREADS
    cputhreads_per_jlthread = floor(Int, cputhreads / jlthreads)
    blasthreads_per_jlthread = BLAS.get_num_threads()
    if blasthreads_per_jlthread == 1
        if jlthreads < Sys.CPU_THREADS
            hints && @info(
                "blasthreads_per_jlthread == 1 && jlthreads < cputhreads. You should set BLAS.set_num_threads($cputhreads_per_jlthread) or try to increase the number of Julia threads to $cputhreads."
            )
            return :yellow
        elseif jlthreads == cputhreads
            return :green
        else
            hints && @warn(
                "jlthreads > cputhreads. You should decrease the number of Julia threads to $cputhreads."
            )
            return :red
        end
    elseif blasthreads_per_jlthread < cputhreads_per_jlthread
        hints && @info(
            "blasthreads_per_jlthread < cputhreads_per_jlthread. You should increase the number of MKL threads, i.e. BLAS.set_num_threads($cputhreads_per_jlthread)."
        )
        return :yellow
    elseif blasthreads_per_jlthread == cputhreads_per_jlthread
        return :green
    else
        hints && @warn(
            "blasthreads_per_jlthread > cputhreads_per_jlthread. You should decrease the number of MKL threads, i.e. BLAS.set_num_threads($cputhreads_per_jlthread)."
        )
        return :red
    end
end

function _color_openblas_num_threads(; hints=false)
    # BLAS uses `blasthreads` many threads in total
    cputhreads = Sys.CPU_THREADS
    blasthreads = BLAS.get_num_threads()
    jlthreads = Threads.nthreads()
    if jlthreads != 1
        if blasthreads == 1
            return :green
        else
            # Not sure about this case...
            if blasthreads < jlthreads
                hints && @warn(
                    "jlthreads != 1 && blasthreads < jlthreads. You should set BLAS.set_num_threads(1)."
                )
                return :red
            elseif blasthreads < cputhreads
                hints && @info(
                    "jlthreads != 1 && blasthreads < cputhreads. You should either set BLAS.set_num_threads(1) (recommended!) or at least BLAS.set_num_threads($cputhreads)."
                )
                return :yellow
            elseif blasthreads == cputhreads
                hints && @info(
                    "For jlthreads != 1 we strongly recommend to set BLAS.set_num_threads(1)."
                )
                return :green
            else
                hints && @warn(
                    "jlthreads != 1 && blasthreads > cputhreads. You should set BLAS.set_num_threads(1) (recommended!) or at least BLAS.set_num_threads($cputhreads)."
                )
                return :red
            end
        end
    else
        # single Julia thread
        if blasthreads < cputhreads
            hints && @info(
                "blasthreads < cputhreads. You should increase the number of OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads)."
            )
            return :yellow
        elseif blasthreads == cputhreads
            return :green
        else
            hints && @warn(
                "blasthreads > cputhreads. You should decrease the number of OpenBLAS threads, i.e. BLAS.set_num_threads($corse)."
            )
            return :red
        end
    end
end

function _general_hints()
    jlthreads = Threads.nthreads()
    cputhreads = Sys.CPU_THREADS
    thread_cpuids = getcpuids()
    if jlthreads > cputhreads
        @warn(
            "jlthreads > cputhreads. You should decrease the number of Julia threads to $cputhreads."
        )
    elseif jlthreads < cputhreads
        @info(
            "jlthreads < cputhreads. Perhaps increase number of Julia threads to $cputhreads?"
        )
    end
    if length(unique(thread_cpuids)) < jlthreads
        @warn("Overlap: Some Julia threads are running on the same cpu threads")
    end
    return nothing
end