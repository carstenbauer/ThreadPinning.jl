"""
$(SIGNATURES)
Print information about Julia threads, e.g. on which CPU-threads (i.e. cores if
hyperthreading is disabled) they are running.

Keyword arguments:
* `color` (default: `true`): Toggle between colored and black-and-white output.
* `blocksize` (default: `32`): Wrap to a new line after `blocksize` many CPU-threads.
* `hyperthreading` (default: `true`): If `true`, we (try to) highlight CPU-threads
  associated with hyperthreading in the `color=true` output.
* `blas` (default: `false`): Show information about BLAS threads as well.
* `hints` (default: `false`): Give some hints about how to improve the threading related
  settings.
* `groupby` (default: `:sockets`): Options are `:sockets`, `:numa`, `:cores`, or `:none`.
* `masks` (default: `false`): Show the affinity masks of all Julia threads.
* `threadpool` (default: `:all`): Only consider Julia threads in the given thread pool.
                                  Supported values are `:all`, `:default`, and
                                  `:interactive`. Only works for Julia >= 1.9.
"""
function threadinfo(io = getstdout(); blas = false, hints = false, color = true,
                    masks = false,
                    groupby = :sockets, threadpool = :all, kwargs...)
    # general info
    @static if VERSION >= v"1.9-"
        if threadpool == :default || threadpool == :interactive
            jlthreads = Base.Threads.nthreads(threadpool)
            if jlthreads == 0
                println(io, "No threads in threadpool $threadpool found.")
                return nothing
            end
            thread_cpuids = filter(i -> Threads.threadpool(i) == threadpool,
                                   1:Threads.nthreads())
        elseif threadpool == :all
            jlthreads = Base.Threads.nthreads()
            thread_cpuids = getcpuids()
        else
            throw(ArgumentError("Unknown value for `threadpool` keyword argument. Supported " *
                                "values are `:all`, `:default`, and `:interactive`."))
        end
    else
        jlthreads = Base.Threads.nthreads()
        thread_cpuids = getcpuids()
    end
    @assert length(thread_cpuids) == jlthreads
    occupied_cputhreads = length(unique(thread_cpuids))
    cputhreads = Sys.CPU_THREADS
    # visualize current pinning
    println(io)
    _visualize_affinity(io; thread_cpuids, color, groupby, kwargs...)
    print(io, "Julia threads: ")
    if color
        printstyled(io, jlthreads, "\n"; color = jlthreads > cputhreads ? :red : :green)
    else
        printstyled(io, jlthreads, jlthreads > cputhreads ? "(!)" : "", "\n")
    end
    print(io, "├ Occupied CPU-threads: ")
    if color
        printstyled(io, occupied_cputhreads, "\n";
                    color = occupied_cputhreads < jlthreads ? :red : :green)
    else
        printstyled(io, occupied_cputhreads, occupied_cputhreads < jlthreads ? "(!)" : "",
                    "\n")
    end
    print(io, "└ Mapping (Thread => CPUID):")
    # print(io, "   ")
    for (tid, core) in pairs(thread_cpuids)
        print(io, " $tid => $core,")
        if tid == 5
            print(io, " ...")
            break
        end
    end
    println(io, "\n")
    if blas
        libblas = BLAS_lib()
        println(io, "BLAS: ", libblas)
        if contains(libblas, "openblas")
            print(io, "└ openblas_get_num_threads: ")
            if color
                printstyled(io, BLAS.get_num_threads(), "\n";
                            color = _color_openblas_num_threads())
            else
                printstyled(io, BLAS.get_num_threads(),
                            _color_openblas_num_threads() == :red ? "(!)" : "",
                            "\n")
            end
            println(io)
            _color_openblas_num_threads(; hints)
        elseif contains(libblas, "mkl")
            print(io, "├ mkl_get_num_threads: ")
            if color
                printstyled(io, BLAS.get_num_threads(), "\n";
                            color = _color_mkl_num_threads())
            else
                printstyled(io, BLAS.get_num_threads(),
                            _color_mkl_num_threads() == :red ? "(!)" : "",
                            "\n")
            end
            println(io, "└ mkl_get_dynamic: ", Bool(mkl_get_dynamic()))
            println(io)
            _color_mkl_num_threads(; hints)
        end
    end
    if masks
        print_affinity_masks(io; groupby)
    end
    hints && _general_hints()
    return nothing
end

function _visualize_affinity(io = getstdout();
                             thread_cpuids = getcpuids(),
                             blocksize = 16,
                             color = true,
                             groupby = :sockets,
                             hyperthreading = hyperthreading_is_enabled())
    ncpuids = Sys.CPU_THREADS
    cpuids_grouped = if groupby in (:sockets, :socket)
        cpuids_per_socket()
    elseif groupby in (:numa, :NUMA)
        cpuids_per_numa()
    elseif groupby in (:core, :cores)
        cpuids_per_core()
    else
        [cpuids_all()]
    end
    printstyled(io, "| "; bold = true)
    for (i, cpuids) in pairs(cpuids_grouped)
        for (k, cpuid) in pairs(cpuids)
            if color
                if cpuid in thread_cpuids
                    printstyled(io, cpuid;
                                bold = true,
                                color = if (hyperthreading && ishyperthread(cpuid))
                                    :light_magenta
                                else
                                    :yellow
                                end)
                else
                    printstyled(io, cpuid;
                                color = if (hyperthreading && ishyperthread(cpuid))
                                    :light_black
                                else
                                    :default
                                end)
                end
            else
                if cpuid in thread_cpuids
                    printstyled(io, cpuid; bold = true)
                else
                    print(io, "_")
                end
            end
            if !(cpuid == last(cpuids))
                print(io, ",")
                mod(k, blocksize) == 0 && print(io, "\n  ")
            end
        end
        # print(io, " | ")
        if ncpuids > 32
            printstyled(io, " |"; bold = true)
            if !(i == length(cpuids_grouped))
                println(io)
                printstyled(io, "| "; bold = true)
            end
        else
            printstyled(io, " | "; bold = true)
        end
    end
    println(io)
    # legend
    println(io)
    if color
        printstyled(io, "#"; bold = true, color = :yellow)
    else
        printstyled(io, "#"; bold = true)
    end
    print(io, " = Julia thread, ")
    if hyperthreading
        printstyled(io, "#"; color = :light_black)
        print(io, " = HT, ")
        printstyled(io, "#"; bold = true, color = :light_magenta)
        print(io, " = Julia thread on HT, ")
    end
    if groupby in (:sockets, :socket)
        printstyled(io, "|"; bold = true)
        print(io, " = Socket seperator")
    elseif groupby in (:numa, :NUMA)
        printstyled(io, "|"; bold = true)
        print(io, " = NUMA seperator")
    elseif groupby in (:core, :cores)
        printstyled(io, "|"; bold = true)
        print(io, " = Core seperator")
    end
    println(io, "\n")
    return nothing
end

function _color_mkl_num_threads(; hints = false)
    jlthreads = Threads.nthreads()
    cputhreads = Sys.CPU_THREADS
    cputhreads_per_jlthread = floor(Int, cputhreads / jlthreads)
    blasthreads_per_jlthread = BLAS.get_num_threads()
    if blasthreads_per_jlthread == 1
        if jlthreads < Sys.CPU_THREADS
            hints &&
                @info("blasthreads_per_jlthread == 1 && jlthreads < cputhreads. You "*
                      "should set BLAS.set_num_threads($cputhreads_per_jlthread) or try "*
                      "to increase the number of Julia threads to $cputhreads.")
            return :yellow
        elseif jlthreads == cputhreads
            return :green
        else
            hints &&
                @warn("jlthreads > cputhreads. You should decrease the number of Julia "*
                      "threads to $cputhreads.")
            return :red
        end
    elseif blasthreads_per_jlthread < cputhreads_per_jlthread
        hints &&
            @info("blasthreads_per_jlthread < cputhreads_per_jlthread. You should "*
                  "increase the number of MKL threads, i.e. "*
                  "BLAS.set_num_threads($cputhreads_per_jlthread).")
        return :yellow
    elseif blasthreads_per_jlthread == cputhreads_per_jlthread
        return :green
    else
        hints &&
            @warn("blasthreads_per_jlthread > cputhreads_per_jlthread. You should "*
                  "decrease the number of MKL threads, i.e. "*
                  "BLAS.set_num_threads($cputhreads_per_jlthread).")
        return :red
    end
end

function _color_openblas_num_threads(; hints = false)
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
                hints &&
                    @warn("jlthreads != 1 && blasthreads < jlthreads. You should set "*
                          "BLAS.set_num_threads(1).")
                return :red
            elseif blasthreads < cputhreads
                hints &&
                    @info("jlthreads != 1 && blasthreads < cputhreads. You should either "*
                          "set BLAS.set_num_threads(1) (recommended!) or at least "*
                          "BLAS.set_num_threads($cputhreads).")
                return :yellow
            elseif blasthreads == cputhreads
                hints &&
                    @info("For jlthreads != 1 we strongly recommend to set "*
                          "BLAS.set_num_threads(1).")
                return :green
            else
                hints &&
                    @warn("jlthreads != 1 && blasthreads > cputhreads. You should set "*
                          "BLAS.set_num_threads(1) (recommended!) or at least "*
                          "BLAS.set_num_threads($cputhreads).")
                return :red
            end
        end
    else
        # single Julia thread
        if blasthreads < cputhreads
            hints &&
                @info("blasthreads < cputhreads. You should increase the number of "*
                      "OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads).")
            return :yellow
        elseif blasthreads == cputhreads
            return :green
        else
            hints &&
                @warn("blasthreads > cputhreads. You should decrease the number of "*
                      "OpenBLAS threads, i.e. BLAS.set_num_threads($cputhreads).")
            return :red
        end
    end
end

function _general_hints()
    jlthreads = Threads.nthreads()
    cputhreads = Sys.CPU_THREADS
    thread_cpuids = getcpuids()
    if jlthreads > cputhreads
        @warn("jlthreads > cputhreads. You should decrease the number of Julia threads "*
              "to $cputhreads.")
    elseif jlthreads < cputhreads
        @info("jlthreads < cputhreads. Perhaps increase number of Julia threads to "*
              "$cputhreads?")
    end
    if length(unique(thread_cpuids)) < jlthreads
        @warn("Overlap: Some Julia threads are running on the same CPU-threads")
    end
    return nothing
end
