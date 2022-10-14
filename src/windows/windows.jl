module Windows

import ..ThreadPinning: SysInfo

include("types.jl")
include("error_codes.jl")

const kernel32 = "kernel32"

function get_current_processor_number()
    @ccall kernel32.GetCurrentProcessorNumber()::DWORD
end

# function get_system_info()
#     sysinfo = Ref{SYSTEM_INFO}()
#     @ccall kernel32.GetSystemInfo(sysinfo::Ptr{SYSTEM_INFO})::Cvoid
#     return sysinfo[]
# end

# function get_native_system_info()
#     sysinfo = Ref{SYSTEM_INFO}()
#     @ccall kernel32.GetNativeSystemInfo(sysinfo::Ptr{SYSTEM_INFO})::Cvoid
#     @show get_last_error()
#     return sysinfo[]
# end

function get_logical_processor_information()
    # based on https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformation#examples
    buffer = Vector{SYSTEM_LOGICAL_PROCESSOR_INFORMATION}(undef, 0)
    returned_length = Ref(zero(DWORD))
    done = false
    while !done
        rc = @ccall kernel32.GetLogicalProcessorInformation(buffer::Ptr{
                                                                        SYSTEM_LOGICAL_PROCESSOR_INFORMATION
                                                                        },
                                                            returned_length::DWORD_PTR)::DWORD
        if rc == false
            if get_last_error() == "ERROR_INSUFFICIENT_BUFFER"
                nelements = returned_length[] ÷ sizeof(eltype(buffer))
                buffer = Vector{SYSTEM_LOGICAL_PROCESSOR_INFORMATION}(undef, nelements)
            else
                error("Error: ", get_last_error())
            end
        else
            done = true # leave while loop
        end
    end
    return buffer
end

"Helper function to count set bits in the processor mask."
_countsetbits(proc_mask::ULONG_PTR) = count(isequal('1'), bitstring(proc_mask))

function get_sysinfo()
    buffer = get_logical_processor_information()
    current_cpuid = 0
    current_socket = 0
    current_numa = 0
    nnuma = 0
    ncores = 0
    ncputhreads = 0
    nsockets = 0
    ishyperthread = Bool[]
    cpuids_sockets = Vector{Int}[Int[] for _ in 1:1] # only single socket supported for now
    cpuids_numa = Vector{Int}[Int[] for _ in 1:1]  # only single numa domain supported for now
    for elem in buffer
        if elem.Relationship == RelationNumaNode
            # Non-NUMA systems report a single record of this type.
            nnuma += 1
        elseif elem.Relationship == RelationProcessorCore
            ncores += 1
            # A hyperthreaded core supplies more than one logical processor.
            logical_procs_in_this_core = _countsetbits(elem.ProcessorMask)
            for i in 1:logical_procs_in_this_core
                if i == 1
                    push!(ishyperthread, false)
                else
                    push!(ishyperthread, true)
                end
                push!(cpuids_sockets[current_socket + 1], current_cpuid)
                push!(cpuids_numa[current_numa + 1], current_cpuid)
                ncputhreads += 1
                current_cpuid += 1
            end
            # ncputhreads += logical_procs_in_this_core

        elseif elem.Relationship == RelationCache
            # Cache data is in elem.DUMMYUNIONNAME, one CACHE_DESCRIPTOR structure for each cache.
            # TODO.
            # Cache = &ptr->Cache;
            # if (Cache->Level == 1)
            # {
            #     processorL1CacheCount++;
            # }
            # else if (Cache->Level == 2)
            # {
            #     processorL2CacheCount++;
            # }
            # else if (Cache->Level == 3)
            # {
            #     processorL3CacheCount++;
            # }
            # break;
            nothing
        elseif elem.Relationship == RelationProcessorPackage
            # Logical processors share a physical package.
            nsockets += 1
        else
            error("Unsupported LOGICAL_PROCESSOR_RELATIONSHIP value: $(elem.Relationship)")
        end
    end
    @assert ncputhreads == Sys.CPU_THREADS
    if nsockets > 1 || nnuma > 1
        error("On windows, ThreadPinning.jl does currently only support single socket and single NUMA domain system. Your system seems to have $nsockets sockets and $nnuma NUMA domains.")
    end
    return SysInfo(nsockets, nnuma, ncputhreads > ncores, collect(0:(ncputhreads - 1)),
                   cpuids_sockets, cpuids_numa, ishyperthread)
end

function get_last_error()
    err_code = @ccall kernel32.GetLastError()::DWORD
    return get(ERROR_CODES_LOOKUP, Int(err_code), "Unknown error code: $err_code")
end

end #module
