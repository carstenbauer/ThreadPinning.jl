##
##
## -------------- API --------------
##
##

"""
$(SIGNATURES)
Print information about Julia threads, e.g. on which CPU-threads (i.e. cores if
hyperthreading is disabled) they are running.

Keyword arguments:
* `compact` (default: `true`): Toggle between compact and "cores before hyperthreads" ordering.
* `color` (default: `true`): Toggle between colored and black-and-white output.
* `blocksize` (default: `16`): Wrap to a new line after `blocksize` many CPU-threads.
   May also be set to `:numa` in which case the line break will occur after each numa domain.
* `hyperthreads` (default: `true` if auto-detected): If `true`, we (try to) highlight CPU-threads
  that aren't the first threads within a CPU-core.
* `blas` (default: `false`): Show information about BLAS threads as well.
* `slurm` (default: `false`): Only show the part of the system that is covered by the active SLURM allocation.
* `hints` (default: `false`): Give some hints about how to improve the threading related
  settings.
* `groupby` (default: `:sockets`): Options are `:sockets`, `:numa`, `:cores`, or `:none`.
* `masks` (default: `false`): Show the affinity masks of all Julia threads.
* `threadpool` (default: `:default`): Only consider Julia threads in the given thread pool.
                                  Supported values are `:default`, `:interactive`, and
                                  `:all`. Only works for Julia >= 1.9.
* `efficiency` (default: `true` if auto-detected): If `true`, we highlight (underline)
  CPU-threads that belong to efficiency cores.
* `logical` (default: `false`): Toggle between logical and "physical" CPU-thread indices.
"""
function threadinfo end

##
##
## -------------- Internals / Implementation --------------
##
##

module ThreadInfo

import ThreadPinning: threadinfo
using ThreadPinning: getstdout
import ..SLURM
import SysInfo
import ThreadPinningCore

function threadinfo(io = getstdout(); blas = false, hints = false, color = true,
        masks = false,
        groupby = :sockets, threadpool = :default, slurm = false, compact = true,
        logical = false, efficiency = SysInfo.ncorekinds() > 1,
        hyperthreads = SysInfo.hyperthreading_is_enabled(),
        kwargs...)
    # which sys object
    sys = !slurm ? SysInfo.stdsys() : SLURM.slurmsys()

    # print header
    SysInfo.Internals._print_sysinfo_header(;
        sys = SysInfo.stdsys(), io, gpu = false, always_show_total = true)

    # slurm info
    if slurm
        if SLURM.isslurmjob()
            ncput = SysInfo.ncputhreads(; sys)
            printstyled(io,
                "\nSLURM: ",
                ncput,
                " assigned CPU-threads",
                ncput == SysInfo.ncputhreads() ? " (entire node).\n" :
                ". Will only show those below.\n";
                color = color ? :red : :default)
        else
            printstyled(io,
                "\nSLURM: Session doesn't seem to be running in a SLURM allocation.\n";
                color = color ? :red : :default)
        end
    else
        if SLURM.isslurmjob()
            printstyled(io,
                "\nYou seem to be inside of a SLURM allocation. Consider using `threadinfo(; slurm=true)`.\n";
                color = color ? :red : :default)
        end
    end
    if !efficiency && SysInfo.ncorekinds(; sys) > 1
        printstyled(io,
            "\nYour system seems to have CPU-cores of varying power efficiency. Consider using `threadinfo(; efficiency=true)`.\n";
            color = color ? :red : :default)
    elseif efficiency && SysInfo.ncorekinds(; sys) == 1
        printstyled(io,
            "\nYour system doesn't seem to multiple CPU-core kinds. Won't be highlighting any efficiency cores.`.\n";
            color = color ? :red : :default)
    end
    println(io)

    # query cpuids of Julia threads
    @static if Sys.islinux()
        threads_cpuids = ThreadPinningCore.getcpuids(; threadpool)
        njlthreads = length(threads_cpuids)
        if njlthreads == 0
            printstyled(io, "No threads in threadpool :$threadpool.\n\n";
                color = color ? :red : :default)
            # return
        end
    else
        threads_cpuids = Int[]
        njlthreads = length(ThreadPinningCore.threadids(; threadpool))
        printstyled(
            io, "Unsupported OS: Won't be able to highlight Julia threads.\n\n";
            color = color ? :red : :default)
    end

    printstyled(io, "Julia threads: \t", njlthreads;
        bold = true, color = color ? :green : :default)
    if threadpool == :all
        printstyled(
            io, " (", Threads.nthreads(:default), " + ", Threads.nthreads(:interactive),
            ")"; bold = true, color = color ? :green : :default)
    end
    println(io)

    # visualization
    visualization(; sys,
        threadpool, threads_cpuids, color, groupby, slurm, compact,
        logical, efficiency, hyperthreads, kwargs...)

    # extra information
    @static if Sys.islinux()
        s = (; color = :light_black)
        printstyled(io, "\n(Mapping:"; s...)
        for (tid, core) in pairs(threads_cpuids)
            printstyled(io, " $tid => $core,"; s...)
            if tid == 5
                printstyled(io, " ..."; s...)
                break
            end
        end
        println(io, ")")
    end

    # if blas
    #     println(io)
    #     libblas = BLAS_lib()
    #     println(io, "BLAS: ", libblas)
    #     if contains(libblas, "openblas")
    #         print(io, "└ openblas_get_num_threads: ")
    #         if color
    #             printstyled(io, BLAS.get_num_threads(), "\n";
    #                 color = _color_openblas_num_threads())
    #         else
    #             printstyled(io, BLAS.get_num_threads(),
    #                 _color_openblas_num_threads() == :red ? "(!)" : "",
    #                 "\n")
    #         end
    #         println(io)
    #         _color_openblas_num_threads(; hints)
    #     elseif contains(libblas, "mkl")
    #         print(io, "├ mkl_get_num_threads: ")
    #         if color
    #             printstyled(io, BLAS.get_num_threads(), "\n";
    #                 color = _color_mkl_num_threads())
    #         else
    #             printstyled(io, BLAS.get_num_threads(),
    #                 _color_mkl_num_threads() == :red ? "(!)" : "",
    #                 "\n")
    #         end
    #         println(io, "└ mkl_get_dynamic: ", Bool(mkl_get_dynamic()))
    #         println(io)
    #         _color_mkl_num_threads(; hints)
    #     end
    # end
    if masks
        print_affinity_masks(; groupby, threadpool, io)
    end
    # hints && _general_hints()
    return
end

function choose_blocksize(io, sys)
    _, cols = displaysize(io)
    n = SysInfo.ncputhreads(; sys)
    ndigits = floor(Int, log10(n)) + 1
    blocksize = (cols - 10) ÷ (ndigits + 1)
    return min(blocksize, 16)
end

function visualization(io = getstdout();
        sys = SysInfo.stdsys(),
        threadpool = :default,
        threads_cpuids = ThreadPinningCore.getcpuids(; threadpool),
        blocksize = choose_blocksize(io, sys),
        color = true,
        groupby = :sockets,
        slurm = false,
        compact = true,
        logical = false,
        efficiency = false,
        hyperthreads = SysInfo.hyperthreading_is_enabled(),
        legend = true)
    # preparation
    ncputhreads = SysInfo.ncputhreads(; sys)
    if groupby in (:sockets, :socket)
        f = (i) -> SysInfo.socket(i; compact, sys)
        n = SysInfo.nsockets(; sys)
        label = "CPU socket"
    elseif groupby in (:numa, :NUMA)
        f = (i) -> SysInfo.numa(i; compact, sys)
        n = SysInfo.nnuma(; sys)
        label = "NUMA domain"
    elseif groupby in (:core, :cores)
        f = (i) -> SysInfo.core(i; sys)
        n = SysInfo.ncores(; sys)
        label = "Core"
    else
        throw(ArgumentError("Invalid groupby argument. Valid arguments are :socket, :numa, and :core."))
    end

    blocksize_was_numa = blocksize == :numa
    id = (i) -> SysInfo.id(i; sys)

    # printing loop
    println(io)
    for i in 1:n
        cpuids = f(i)
        printstyled(io, "$(label) $i\n"; bold = true, color = color ? :cyan : :default)
        print(io, "  ")
        for (k, cpuid) in pairs(cpuids)
            if blocksize_was_numa && groupby in (:sockets, :socket)
                blocksize = length(SysInfo.numa(SysInfo.cpuid_to_numanode(cpuid); sys))
            end
            if color
                if cpuid in threads_cpuids
                    colorval = if count(==(cpuid), threads_cpuids) > 1
                        :red
                    elseif (hyperthreads && SysInfo.ishyperthread(cpuid; sys))
                        :light_magenta
                    else
                        :yellow
                    end
                    printstyled(io, logical ? id(cpuid) : cpuid;
                        bold = true,
                        color = color ? colorval : :default,
                        underline = efficiency && SysInfo.isefficiencycore(cpuid; sys))
                else
                    printstyled(io, logical ? id(cpuid) : cpuid;
                        color = if (hyperthreads && SysInfo.ishyperthread(cpuid; sys))
                            :light_black
                        else
                            :default
                        end,
                        underline = efficiency && SysInfo.isefficiencycore(cpuid; sys))
                end
            else
                if cpuid in threads_cpuids
                    printstyled(io, logical ? id(cpuid) : cpuid; bold = true)
                else
                    print(io, "_")
                end
            end
            if !(cpuid == last(cpuids))
                print(io, ",")
                mod(k, blocksize) == 0 && print(io, "\n  ")
            end
        end
        if i == n
            println(io)
        else
            println(io, "\n")
        end
    end
    println(io)

    # legend
    if legend
        println(io)
        if color
            printstyled(io, "#"; bold = true, color = color ? :yellow : :default)
        else
            printstyled(io, "#"; bold = true)
        end
        print(io, " = Julia thread")
        if hyperthreads
            print(io, ", ")
            printstyled(io, "#"; bold = true, color = color ? :light_magenta : :default)
            print(io, " = Julia thread on HT")
        end
        print(io, ", ")
        printstyled(io, "#"; bold = true, color = color ? :red : :default)
        print(io, " = >1 Julia thread")
        if efficiency
            print(io, ", ")
            printstyled(io, "#"; underline = true)
            print(io, " = Efficiency core")
        end
        println(io)
    end
    return
end

# function _color_mkl_num_threads(; hints = false)
#     jlthreads = Threads.nthreads()
#     cputhreads = ncputhreads()
#     cputhreads_per_jlthread = floor(Int, cputhreads / jlthreads)
#     blasthreads_per_jlthread = BLAS.get_num_threads()
#     if blasthreads_per_jlthread == 1
#         if jlthreads < ncputhreads()
#             hints &&
#                 @info("blasthreads_per_jlthread == 1 && jlthreads < cputhreads. You "*
#                       "should set BLAS.set_num_threads($cputhreads_per_jlthread) or try "*
#                       "to increase the number of Julia threads to $cputhreads.")
#             return :yellow
#         elseif jlthreads == cputhreads
#             return :green
#         else
#             hints &&
#                 @warn("jlthreads > cputhreads. You should decrease the number of Julia "*
#                 "threads to $cputhreads.")
#             return :red
#         end
#     elseif blasthreads_per_jlthread < cputhreads_per_jlthread
#         hints &&
#             @info("blasthreads_per_jlthread < cputhreads_per_jlthread. You should "*
#                   "increase the number of MKL threads, i.e. "*
#                   "BLAS.set_num_threads($cputhreads_per_jlthread).")
#         return :yellow
#     elseif blasthreads_per_jlthread == cputhreads_per_jlthread
#         return :green
#     else
#         hints &&
#             @warn("blasthreads_per_jlthread > cputhreads_per_jlthread. You should "*
#                   "decrease the number of MKL threads, i.e. "*
#                   "BLAS.set_num_threads($cputhreads_per_jlthread).")
#         return :red
#     end
# end

# function _color_openblas_num_threads(; hints = false)
#     # BLAS uses `blasthreads` many threads in total
#     cputhreads = ncputhreads()
#     blasthreads = BLAS.get_num_threads()
#     jlthreads = Threads.nthreads()
#     if jlthreads != 1
#         if blasthreads == 1
#             return :green
#         else
#             # Not sure about this case...
#             if blasthreads < jlthreads
#                 hints &&
#                     @warn("jlthreads != 1 && blasthreads < jlthreads. You should set "*
#                     "BLAS.set_num_threads(1).")
#                 return :red
#             elseif blasthreads < cputhreads
#                 hints &&
#                     @info("jlthreads != 1 && blasthreads < cputhreads. You should either "*
#                           "set BLAS.set_num_threads(1) (recommended!) or at least "*
#                           "BLAS.set_num_threads($cputhreads).")
#                 return :yellow
#             elseif blasthreads == cputhreads
#                 hints &&
#                     @info("For jlthreads != 1 we strongly recommend to set "*
#                     "BLAS.set_num_threads(1).")
#                 return :green
#             else
#                 hints &&
#                     @warn("jlthreads != 1 && blasthreads > cputhreads. You should set "*
#                           "BLAS.set_num_threads(1) (recommended!) or at least "*
#                           "BLAS.set_num_threads($cputhreads).")
#                 return :red
#             end
#         end
#     else
#         # single Julia thread
#         if blasthreads < cputhreads
#             hints &&
#                 @info("blasthreads < cputhreads. You should increase the number of "*
#                 "OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads).")
#             return :yellow
#         elseif blasthreads == cputhreads
#             return :green
#         else
#             hints &&
#                 @warn("blasthreads > cputhreads. You should decrease the number of "*
#                 "OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads).")
#             return :red
#         end
#     end
# end

# function _general_hints()
#     jlthreads = Threads.nthreads()
#     cputhreads = ncputhreads()
#     threads_cpuids = getcpuids()
#     if jlthreads > cputhreads
#         @warn("jlthreads > cputhreads. You should decrease the number of Julia threads "*
#         "to $cputhreads.")
#     elseif jlthreads < cputhreads
#         @info("jlthreads < cputhreads. Perhaps increase number of Julia threads to "*
#         "$cputhreads?")
#     end
#     if length(unique(threads_cpuids)) < jlthreads
#         @warn("Overlap: Some Julia threads are running on the same CPU-threads")
#     end
#     return
# end

end # module
