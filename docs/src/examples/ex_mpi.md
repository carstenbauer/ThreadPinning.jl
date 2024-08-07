# [MPI + Threads](@id mpi_threads)

ThreadPinning.jl has dedicated support for pinning Julia threads of MPI ranks in MPI applications, see [Querying - MPI](@ref api_mpi_querying) and [Pinning - MPI](@ref api_mpi_pinning). Note that you can use these tools irrespective of whether your MPI applications is pure (i.e. each MPI rank runs a single Julia thread) or hybrid (i.e. each MPI ranks runs multiple Julia threads). We demonstrate this with a simple example below.

!!! note
    If your MPI application runs under SLURM (or a similar job scheduler), you may want to consider using the pinning options of SLURM to control the placement of the MPI ranks on the nodes, potentially in conjuction with `pinthreads(:affinitymask)`. See [External Affinity Mask](@ref exaffinitymask) for more information.

## Example code

```julia
using ThreadPinning
using MPI

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
nthreads = Threads.nthreads()

# print system overview
if rank == 0
    for inuma in 1:nnuma()
        println("NUMA node $(inuma): ", numa(inuma))
    end
    println("\n")
end

# print where julia threads are running (before pinning)
hostnames = mpi_gethostnames()
cpuids_before = mpi_getcpuids()
if rank == 0
    println("BEFORE: Where are the Julia threads of the MPI ranks running?")
    for r in 0:length(hostnames)-1
        println("\trank $r is running $(nthreads) Julia threads on the CPU-threads ", cpuids_before[r], " of node ", hostnames[r])
    end
    println("\n")
end

# on each node, pin threads of local MPI ranks to NUMA domains in a round-robin fashion
mpi_pinthreads(:numa)

# print where julia threads are running (after pinning)
cpuids_after = mpi_getcpuids()
if rank == 0
    println("AFTER: Where are the Julia threads of the MPI ranks running?")
    for r in 0:length(hostnames)-1
        println("\trank $r is running $(nthreads) Julia threads on the CPU-threads ", cpuids_after[r], " of node ", hostnames[r])
    end
end
```

## Pure MPI

**Details:** 4 MPI ranks, no multithreading, on a single node.

```julia
NUMA node 1: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143]
NUMA node 2: [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
NUMA node 3: [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175]
NUMA node 4: [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191]
NUMA node 5: [64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207]
NUMA node 6: [80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223]
NUMA node 7: [96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239]
NUMA node 8: [112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255]


BEFORE: Where are the Julia threads of the MPI ranks running?
	rank 0 is running 1 Julia threads on the CPU-threads [123] of node nid004219
	rank 1 is running 1 Julia threads on the CPU-threads [24] of node nid004219
	rank 2 is running 1 Julia threads on the CPU-threads [11] of node nid004219
	rank 3 is running 1 Julia threads on the CPU-threads [192] of node nid004219


AFTER: Where are the Julia threads of the MPI ranks running?
	rank 0 is running 1 Julia threads on the CPU-threads [0] of node nid004219
	rank 1 is running 1 Julia threads on the CPU-threads [16] of node nid004219
	rank 2 is running 1 Julia threads on the CPU-threads [32] of node nid004219
	rank 3 is running 1 Julia threads on the CPU-threads [48] of node nid004219
```

## Hybrid MPI + Threads (single node)

**Details:** 4 MPI ranks, each running two Julia threads, on a single node.

```julia
NUMA node 1: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143]
NUMA node 2: [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
NUMA node 3: [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175]
NUMA node 4: [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191]
NUMA node 5: [64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207]
NUMA node 6: [80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223]
NUMA node 7: [96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239]
NUMA node 8: [112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255]


BEFORE: Where are the Julia threads of the MPI ranks running?
	rank 0 is running 2 Julia threads on the CPU-threads [127, 161] of node nid004219
	rank 1 is running 2 Julia threads on the CPU-threads [96, 72] of node nid004219
	rank 2 is running 2 Julia threads on the CPU-threads [105, 255] of node nid004219
	rank 3 is running 2 Julia threads on the CPU-threads [192, 196] of node nid004219


AFTER: Where are the Julia threads of the MPI ranks running?
	rank 0 is running 2 Julia threads on the CPU-threads [0, 1] of node nid004219
	rank 1 is running 2 Julia threads on the CPU-threads [16, 17] of node nid004219
	rank 2 is running 2 Julia threads on the CPU-threads [32, 33] of node nid004219
	rank 3 is running 2 Julia threads on the CPU-threads [48, 49] of node nid004219
```

## Hybrid MPI + Threads (multiple nodes)

**Details:** 16 MPI ranks, each running two Julia threads, distributed across 4 nodes (4 MPI ranks per node).

```julia
NUMA node 1: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143]
NUMA node 2: [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
NUMA node 3: [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175]
NUMA node 4: [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191]
NUMA node 5: [64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207]
NUMA node 6: [80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223]
NUMA node 7: [96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239]
NUMA node 8: [112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255]


BEFORE: Where are the Julia threads of the MPI ranks running?
	rank 0 is running 2 Julia threads on the CPU-threads [127, 253] of node nid004406
	rank 1 is running 2 Julia threads on the CPU-threads [113, 182] of node nid004406
	rank 2 is running 2 Julia threads on the CPU-threads [109, 138] of node nid004406
	rank 3 is running 2 Julia threads on the CPU-threads [26, 115] of node nid004406
	rank 4 is running 2 Julia threads on the CPU-threads [4, 146] of node nid005218
	rank 5 is running 2 Julia threads on the CPU-threads [101, 236] of node nid005218
	rank 6 is running 2 Julia threads on the CPU-threads [42, 255] of node nid005218
	rank 7 is running 2 Julia threads on the CPU-threads [8, 90] of node nid005218
	rank 8 is running 2 Julia threads on the CPU-threads [80, 237] of node nid005908
	rank 9 is running 2 Julia threads on the CPU-threads [23, 198] of node nid005908
	rank 10 is running 2 Julia threads on the CPU-threads [5, 47] of node nid005908
	rank 11 is running 2 Julia threads on the CPU-threads [54, 26] of node nid005908
	rank 12 is running 2 Julia threads on the CPU-threads [42, 143] of node nid005915
	rank 13 is running 2 Julia threads on the CPU-threads [8, 120] of node nid005915
	rank 14 is running 2 Julia threads on the CPU-threads [238, 217] of node nid005915
	rank 15 is running 2 Julia threads on the CPU-threads [27, 159] of node nid005915


AFTER: Where are the Julia threads of the MPI ranks running?
	rank 0 is running 2 Julia threads on the CPU-threads [0, 1] of node nid004406
	rank 1 is running 2 Julia threads on the CPU-threads [16, 17] of node nid004406
	rank 2 is running 2 Julia threads on the CPU-threads [32, 33] of node nid004406
	rank 3 is running 2 Julia threads on the CPU-threads [48, 49] of node nid004406
	rank 4 is running 2 Julia threads on the CPU-threads [0, 1] of node nid005218
	rank 5 is running 2 Julia threads on the CPU-threads [16, 17] of node nid005218
	rank 6 is running 2 Julia threads on the CPU-threads [32, 33] of node nid005218
	rank 7 is running 2 Julia threads on the CPU-threads [48, 49] of node nid005218
	rank 8 is running 2 Julia threads on the CPU-threads [0, 1] of node nid005908
	rank 9 is running 2 Julia threads on the CPU-threads [16, 17] of node nid005908
	rank 10 is running 2 Julia threads on the CPU-threads [32, 33] of node nid005908
	rank 11 is running 2 Julia threads on the CPU-threads [48, 49] of node nid005908
	rank 12 is running 2 Julia threads on the CPU-threads [0, 1] of node nid005915
	rank 13 is running 2 Julia threads on the CPU-threads [16, 17] of node nid005915
	rank 14 is running 2 Julia threads on the CPU-threads [32, 33] of node nid005915
	rank 15 is running 2 Julia threads on the CPU-threads [48, 49] of node nid005915
```