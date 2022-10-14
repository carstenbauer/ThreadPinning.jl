module Windows

import ..ThreadPinning: SysInfo

include("types.jl")
include("error_codes.jl")

const kernel32 = "kernel32"

get_current_processor_number() = @ccall kernel32.GetCurrentProcessorNumber()::DWORD

get_current_processid() = @ccall kernel32.GetCurrentProcessId()::DWORD
function get_processid(process_handle)
    Int(@ccall kernel32.GetProcessId(process_handle::THREAD_HANDLE)::DWORD)
end

# get_current_process() = @ccall kernel32.GetCurrentProcess()::THREAD_HANDLE # doesn't work properly?!
function get_process_handle(procid = get_current_processid())
    dwDesiredAccess = PROCESS_SET_INFORMATION | PROCESS_QUERY_INFORMATION
    # dwDesiredAccess = 0xffff
    @ccall kernel32.OpenProcess(dwDesiredAccess::DWORD, true::Bool,
                                procid::DWORD)::THREAD_HANDLE
end

function get_process_affinity_mask(process_handle = get_process_handle())
    # BOOL GetProcessAffinityMask(
    #   [in]  HANDLE     hProcess,
    #   [out] PDWORD_PTR lpProcessAffinityMask,
    #   [out] PDWORD_PTR lpSystemAffinityMask
    # );
    lpProcessAffinityMask = Ref{DWORD_PTR}()
    lpSystemAffinityMask = Ref{DWORD_PTR}()
    ret = @ccall kernel32.GetProcessAffinityMask(process_handle::THREAD_HANDLE,
                                                 lpProcessAffinityMask::PDWORD_PTR,
                                                 lpSystemAffinityMask::PDWORD_PTR)::Bool
    if ret == true
        return DWORD(UInt(lpProcessAffinityMask[])), DWORD(UInt(lpSystemAffinityMask[]))
    else
        error("Error: $(get_last_error())")
    end
end

# get_current_thread() = @ccall kernel32.GetCurrentThread()::THREAD_HANDLE # doesn't work properly?!
function get_thread_handle(threadid = get_current_threadid())
    dwDesiredAccess = THREAD_SET_INFORMATION | THREAD_QUERY_INFORMATION
    # dwDesiredAccess = 0xffff
    @ccall kernel32.OpenThread(dwDesiredAccess::DWORD, true::Bool,
                               threadid::DWORD)::THREAD_HANDLE
end

function set_thread_affinity_mask(thread_handle, mask)
    @ccall kernel32.SetThreadAffinityMask(thread_handle::THREAD_HANDLE,
                                          mask::DWORD_PTR)::DWORD_PTR
end
function set_thread_affinity(procid::Integer)
    mask = DWORD(1 << procid)
    # @show bitstring(mask)
    ret = set_thread_affinity_mask(get_thread_handle(), Ref(mask))
    if ret == 0
        error("Error: $(get_last_error())")
    else
        # success: return thread's previous affinity mask.
        return DWORD(UInt(ret))
    end
end

function get_thread_affinity_mask(thread_handle::THREAD_HANDLE = get_thread_handle())
    # Based on https://stackoverflow.com/a/6601917/2365675
    mask = DWORD(1)
    old = DWORD(0)

    # try every CPU one by one until one works or none are left
    while mask == true
        old = DWORD(UInt(set_thread_affinity_mask(thread_handle, Ref(mask))))
        if old != false
            # this one worked
            set_thread_affinity_mask(thread_handle, Ref(old)) # restore original
            return old
        else
            if get_last_error() != "ERROR_INVALID_PARAMETER"
                error("unknown error")
            end
        end
        mask <<= 1
    end
    error("failed")
end

function get_threadid(thread_handle)
    Int(@ccall kernel32.GetThreadId(thread_handle::THREAD_HANDLE)::DWORD)
end
get_current_threadid() = Int(@ccall kernel32.GetCurrentThreadId()::DWORD)
function get_threadids()
    nt = Threads.nthreads()
    ids = zeros(Int, nt)
    Threads.@threads :static for i in 1:nt
        ids[i] = get_current_threadid()
    end
    return ids
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
