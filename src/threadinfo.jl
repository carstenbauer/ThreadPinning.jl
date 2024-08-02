##
##
## -------------- API --------------
##
##

"""
    threadinfo(;
        groupby = :sockets,
        threadpool = :default,
        blas = false,
        slurm = false,
        hints = false,
        compact = true,
        hyperthreads = SysInfo.hyperthreading_is_enabled(),
        efficiency = SysInfo.ncorekinds() > 1,
        masks = false,
        coregaps = SysInfo.hyperthreading_is_enabled(),
        logical = false,
        color = true,
        blocksize = choose_blocksize()
    )

Print information about Julia threads, e.g. on which CPU-threads (i.e. cores if
hyperthreading is disabled) they are running.

# Keyword arguments
* `groupby`: Options are `:sockets`, `:numa`, `:cores`, or `:none`.
* `threadpool`: Only consider Julia threads in the given thread pool.
                                  Supported values are `:default`, `:interactive`, and
                                  `:all`.
* `blas`: Visualize BLAS threads instead of Julia threads.
* `slurm`: Only show the part of the system that is covered by the active SLURM allocation.
* `hints`: Try to give some hints about how to improve the threading related
  settings.
* `compact`: Toggle between compact and "cores before hyperthreads" ordering.
* `hyperthreads`: If `true`, we (try to) highlight CPU-threads
  that aren't the first threads within a CPU-core.
* `efficiency`: If `true`, we highlight (underline)
  CPU-threads that belong to efficiency cores.
* `masks`: Show the affinity masks of all Julia threads.
* `coregaps`: Put an extra space ("gap") between different CPU-cores, when printing.
* `logical`: Toggle between logical and "physical" CPU-thread indices.
* `color`: Toggle between colored and black-and-white output.
* `blocksize`: Wrap to a new line after `blocksize` many CPU-threads.
   May also be set to `:numa` in which case the line break will occur after each numa domain.
"""
function threadinfo end

##
##
## -------------- Internals / Implementation --------------
##
##

module ThreadInfo

import ThreadPinning: threadinfo
using ThreadPinning: ThreadPinning, getstdout
import ..SLURM
import ..Utility
import SysInfo
import ThreadPinningCore
using LinearAlgebra: BLAS

function threadinfo(io = getstdout();
        groupby = :sockets,
        threadpool = :default,
        blas = false,
        slurm = false,
        hints = false,
        compact = true,
        hyperthreads = SysInfo.hyperthreading_is_enabled(),
        efficiency = SysInfo.ncorekinds() > 1,
        masks = false,
        coregaps = SysInfo.hyperthreading_is_enabled(),
        logical = false,
        color = true,
        kwargs...)
    # which sys object
    sys = !slurm ? SysInfo.stdsys() : SLURM.slurmsys()

    kwargs_msg_red = (; color = color ? :red : :default, bold = true)

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
                kwargs_msg_red...)
        else
            printstyled(io,
                "\nSLURM: Session doesn't seem to be running in a SLURM allocation.\n";
                kwargs_msg_red...)
        end
    else
        if SLURM.isslurmjob()
            printstyled(io,
                "\nYou seem to be inside of a SLURM allocation. Consider using `threadinfo(; slurm=true)`.\n";
                kwargs_msg_red...)
        end
    end
    if !efficiency && SysInfo.ncorekinds(; sys) > 1
        printstyled(io,
            "\nYour system seems to have CPU-cores of varying power efficiency. Consider using `threadinfo(; efficiency=true)`.\n";
            kwargs_msg_red...)
    elseif efficiency && SysInfo.ncorekinds(; sys) == 1
        printstyled(io,
            "\nYour system doesn't seem to multiple CPU-core kinds. Won't be highlighting any efficiency cores.`.\n";
            kwargs_msg_red...)
    end
    println(io)

    # query cpuids of threads
    local threads_cpuids
    local threadslabel
    local nthreads
    @static if Sys.islinux()
        if blas
            ismkl = contains(Utility.BLAS_lib(), "mkl")
            if ismkl
                threads_cpuids = Int[]
                nthreads = BLAS.get_num_threads()
                printstyled(
                    io, "Intel MKL detected. Won't be able to highlight the BLAS threads.\n\n";
                    kwargs_msg_red...)
            else
                try
                    threads_cpuids = ThreadPinningCore.openblas_getcpuids()
                    threadslabel = "BLAS"
                    nthreads = length(threads_cpuids)
                catch _
                    printstyled(io,
                        "Couldn't get the CPU IDs of the BLAS threads. Maybe you haven't pinned them yet?.\n\n";
                        kwargs_msg_red...)
                    return
                end
            end
        else
            threads_cpuids = ThreadPinningCore.getcpuids(; threadpool)
            nthreads = length(threads_cpuids)
            threadslabel = "Julia"
            if nthreads == 0
                printstyled(io, "No threads in threadpool :$threadpool.\n\n";
                    kwargs_msg_red...)
                # return
            end
        end
    else
        threads_cpuids = Int[]
        nthreads = length(ThreadPinningCore.threadids(; threadpool))
        threadslabel = blas ? "BLAS" : "Julia"
        printstyled(
            io, "Unsupported OS: Won't be able to highlight $(threadslabel) threads.\n\n";
            kwargs_msg_red...)
    end

    printstyled(io, "$(threadslabel) threads: \t", nthreads;
        bold = true, color = color ? (blas ? :red : :green) : :default)
    if threadpool == :all && !blas
        printstyled(
            io, " (", Threads.nthreads(:default), " + ", Threads.nthreads(:interactive),
            ")"; bold = true, color = color ? :green : :default)
    end
    println(io)

    # visualization
    visualization(; sys,
        threadpool, threads_cpuids, color, groupby, slurm, compact,
        logical, efficiency, hyperthreads, threadslabel, coregaps, kwargs...)

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

    if masks
        println(io)
        if blas
            ThreadPinning.openblas_printaffinities(; groupby, io)
        else
            ThreadPinning.printaffinities(; groupby, threadpool, io)
        end
    end
    if hints
        println(io)
        general_hints()
        if contains(Utility.BLAS_lib(), "openblas")
            openblas_hints(; check = false)
        else
            mkl_hints()
        end
    end
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
        threadslabel = "Julia",
        blocksize = choose_blocksize(io, sys),
        color = true,
        groupby = :sockets,
        slurm = false,
        compact = true,
        logical = false,
        efficiency = false,
        hyperthreads = SysInfo.hyperthreading_is_enabled(),
        coregaps = false,
        legend = true)
    # preparation
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

    nsmt = SysInfo.nsmt(; sys)
    blocksize_was_numa = blocksize == :numa
    id = (i) -> SysInfo.id(i; sys)

    # printing loop
    breakline_asap = false
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
                if mod(k, blocksize) == 0
                    breakline_asap = true
                end
                if coregaps
                    if SysInfo.Internals.is_last_hyperthread_in_core(cpuid)
                        print(io, " ")
                        if breakline_asap
                            print(io, "\n  ")
                            breakline_asap = false
                        end
                    end
                else
                    if breakline_asap
                        print(io, "\n  ")
                        breakline_asap = false
                    end
                end
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
        print(io, " = $(threadslabel) thread")
        if hyperthreads
            print(io, ", ")
            printstyled(io, "#"; bold = true, color = color ? :light_magenta : :default)
            print(io, " = $(threadslabel) thread on HT")
        end
        print(io, ", ")
        printstyled(io, "#"; bold = true, color = color ? :red : :default)
        print(io, " = >1 $(threadslabel) thread")
        if efficiency
            print(io, ", ")
            printstyled(io, "#"; underline = true)
            print(io, " = Efficiency core")
        end
        println(io)
    end
    return
end

function mkl_hints(; check = true)
    if check && !contains(Utility.BLAS_lib(), "mkl")
        error("Not using MKL? Can't display MKL hints.")
    end
    jlthreads = Threads.nthreads()
    cputhreads = ThreadPinning.ncputhreads()
    cputhreads_per_jlthread = floor(Int, cputhreads / jlthreads)
    blasthreads_per_jlthread = BLAS.get_num_threads()

    if blasthreads_per_jlthread == 1
        if jlthreads < cputhreads
            @info("blasthreads_per_jlthread == 1 && (# Julia threads) < (# CPU-threads)). You "*
                  "should set BLAS.set_num_threads($cputhreads_per_jlthread) or try "*
                  "to increase the number of Julia threads to $cputhreads.")
        elseif jlthreads > cputhreads
            @warn("# Julia threads > # CPU-threads. You should decrease the number of Julia "*
            "threads to $cputhreads.")
        end
    elseif blasthreads_per_jlthread < cputhreads_per_jlthread
        @info("blasthreads_per_jlthread < cputhreads_per_jlthread. You should "*
              "increase the number of MKL threads, i.e. "*
              "BLAS.set_num_threads($cputhreads_per_jlthread).")
    elseif blasthreads_per_jlthread > cputhreads_per_jlthread
        @warn("blasthreads_per_jlthread > cputhreads_per_jlthread. You should "*
              "decrease the number of MKL threads, i.e. "*
              "BLAS.set_num_threads($cputhreads_per_jlthread).")
    end
    return
end

function openblas_hints(; check = true)
    if check && !contains(Utility.BLAS_lib(), "openblas")
        error("Not using OpenBLAS? Can't display OpenBLAS hints.")
    end
    cputhreads = ThreadPinning.ncputhreads()
    blasthreads = BLAS.get_num_threads()
    jlthreads = Threads.nthreads()
    if jlthreads != 1
        if blasthreads != 1
            # Not sure about this case...
            if blasthreads < jlthreads
                @warn("(# Julia threads) != 1 && (# BLAS threads) < (# Julia threads). You should set "*
                "BLAS.set_num_threads(1).")
            elseif blasthreads < cputhreads
                @info("(# Julia threads) != 1 && (# BLAS threads) < (# CPU-threads). You should either "*
                      "set BLAS.set_num_threads(1) (recommended!) or at least "*
                      "BLAS.set_num_threads($cputhreads).")
            elseif blasthreads == cputhreads
                @info("For (# Julia threads) != 1 we strongly recommend to set "*
                "BLAS.set_num_threads(1).")
            else
                @warn("(# Julia threads) != 1 && (# BLAS threads) > (# CPU-threads). You should set "*
                      "BLAS.set_num_threads(1) (recommended!) or at least "*
                      "BLAS.set_num_threads($cputhreads).")
            end
        end
    else
        # single Julia thread
        if blasthreads < cputhreads
            @info("(# BLAS threads) < (# CPU-threads). You should increase the number of "*
            "OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads).")
        elseif blasthreads > cputhreads
            @warn("(# BLAS threads) > (# CPU-threads). You should decrease the number of "*
            "OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads).")
        end
    end
    return
end

function general_hints()
    jlthreads = Threads.nthreads()
    cputhreads = ThreadPinning.ncputhreads()
    threads_cpuids = ThreadPinning.getcpuids()
    if jlthreads > cputhreads
        @warn("(# Julia threads) > (# CPU-Threads). You should decrease the number of Julia threads "*
        "to $cputhreads.")
    elseif jlthreads < cputhreads
        @info("(# Julia threads) < (# CPU-Threads). Perhaps increase number of Julia threads to "*
        "$cputhreads?")
    end
    if length(unique(threads_cpuids)) < jlthreads
        @warn("Overlap: Some Julia threads are running on the same CPU-threads!")
    end
    return
end

end # module
