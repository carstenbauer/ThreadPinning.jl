# windows datatypes (https://learn.microsoft.com/de-de/windows/win32/winprog/windows-data-types)
const DWORD = Culong
const DWORD_PTR = Ptr{Culong}
const WORD = Cushort
const LPVOID = Ptr{Cvoid}
const BYTE = Cuchar
const ULONG_PTR = Ptr{Culong}

struct SYSTEM_INFO_0_0
    wProcessorArchitecture::WORD
    wReserved::WORD
end

struct SYSTEM_INFO_0 # necessary?!
        dwOemId::DWORD
        DUMMYSTRUCTNAME::SYSTEM_INFO_0_0
end

struct SYSTEM_INFO
    # Definition: https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/ns-sysinfoapi-system_info
    DUMMYUNIONNAME::Union{DWORD, SYSTEM_INFO_0_0};
    dwPageSize::DWORD
    lpMinimumApplicationAddress::LPVOID
    lpMaximumApplicationAddress::LPVOID
    dwActiveProcessorMask::DWORD_PTR
    dwNumberOfProcessors::DWORD
    dwProcessorType::DWORD
    dwAllocationGranularity::DWORD
    wProcessorLevel::WORD
    wProcessorRevision::WORD
end

struct ProcessorCore
    Flags::BYTE
end

struct NumaNode
    NodeNumber::DWORD
end

# const LOGICAL_PROCESSOR_RELATIONSHIP = Cint
@enum LOGICAL_PROCESSOR_RELATIONSHIP begin
    RelationProcessorCore
    RelationNumaNode
    RelationCache
    RelationProcessorPackage
    RelationGroup
    RelationProcessorDie
    RelationNumaNodeEx
    RelationProcessorModule
    RelationAll = 0xffff
end

@enum PROCESSOR_CACHE_TYPE begin
  CacheUnified
  CacheInstruction
  CacheData
  CacheTrace
end
# const PROCESSOR_CACHE_TYPE = Cint

struct CACHE_DESCRIPTOR
    Level::BYTE
    Associativity::BYTE
    LineSize::WORD
    Size::DWORD
    Type::PROCESSOR_CACHE_TYPE
end

struct SYSTEM_LOGICAL_PROCESSOR_INFORMATION
    ProcessorMask::ULONG_PTR
    Relationship::LOGICAL_PROCESSOR_RELATIONSHIP
    # DUMMYUNIONNAME::Union{ProcessorCore, NumaNode, CACHE_DESCRIPTOR, Culonglong}
    DUMMYUNIONNAME::Union{Ptr{ProcessorCore}, Ptr{NumaNode}, Ptr{CACHE_DESCRIPTOR}, Ptr{Culonglong}}
    # DUMMYUNIONNAME::Union{ProcessorCore, NumaNode, CACHE_DESCRIPTOR}
    # DUMMYUNIONNAME::Union{ProcessorCore, NumaNode, CACHE_DESCRIPTOR, NTuple{2, Culonglong}}
    # union {
    #   struct {
    #     BYTE Flags;
    #   } ProcessorCore;
    #   struct {
    #     DWORD NodeNumber;
    #   } NumaNode;
    #   CACHE_DESCRIPTOR Cache;
    #   ULONGLONG        Reserved[2];
    # } ;
end
