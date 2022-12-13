using Test
using ThreadPinning

@testset "lscpu2sysinfo (NOCTUA2LOGIN)" begin
    sinfo = ThreadPinning.lscpu2sysinfo(ThreadPinning.lscpu_NOCTUA2LOGIN)
    @test typeof(sinfo) == ThreadPinning.SysInfo
    @test sinfo.ncores == 64
    @test sinfo.nsockets == 1
    @test sinfo.nnuma == 4
    @test sinfo.hyperthreading == true
    @test sinfo.cpuids == 0:127
    @test length(sinfo.cpuids_sockets) == 1
    @test sinfo.cpuids_sockets[1] == 0:127
    @test length(sinfo.cpuids_numa) == 4
    @test sinfo.cpuids_numa[1] == vcat(0:15, 64:79)
    @test sinfo.cpuids_numa[2] == vcat(16:31, 80:95)
    @test sinfo.cpuids_numa[3] == vcat(32:47, 96:111)
    @test sinfo.cpuids_numa[4] == vcat(48:63, 112:127)
    @test sinfo.ishyperthread == vcat(falses(64), trues(64))
    @test sinfo.cpuids_core == [[0, 64], [1, 65], [2, 66], [3, 67], [4, 68], [5, 69], [6, 70], [7, 71], [8, 72], [9, 73], [10, 74], [11, 75], [12, 76], [13, 77], [14, 78], [15, 79], [16, 80], [17, 81], [18, 82], [19, 83], [20, 84], [21, 85], [22, 86], [23, 87], [24, 88], [25, 89], [26, 90], [27, 91], [28, 92], [29, 93], [30, 94], [31, 95], [32, 96], [33, 97], [34, 98], [35, 99], [36, 100], [37, 101], [38, 102], [39, 103], [40, 104], [41, 105], [42, 106], [43, 107], [44, 108], [45, 109], [46, 110], [47, 111], [48, 112], [49, 113], [50, 114], [51, 115], [52, 116], [53, 117], [54, 118], [55, 119], [56, 120], [57, 121], [58, 122], [59, 123], [60, 124], [61, 125], [62, 126], [63, 127]]
end

@testset "lscpu2sysinfo (NOCTUA2)" begin
    sinfo = ThreadPinning.lscpu2sysinfo(ThreadPinning.lscpu_NOCTUA2)
    @test typeof(sinfo) == ThreadPinning.SysInfo
    @test sinfo.ncores == 128
    @test sinfo.nsockets == 2
    @test sinfo.nnuma == 8
    @test sinfo.hyperthreading == false
    @test sinfo.cpuids == 0:127
    @test length(sinfo.cpuids_sockets) == 2
    @test sinfo.cpuids_sockets[1] == 0:63
    @test sinfo.cpuids_sockets[2] == 64:127
    @test length(sinfo.cpuids_numa) == 8
    @test sinfo.cpuids_numa[1] == 0:15
    @test sinfo.cpuids_numa[2] == 16:31
    @test sinfo.cpuids_numa[3] == 32:47
    @test sinfo.cpuids_numa[4] == 48:63
    @test sinfo.cpuids_numa[5] == 64:79
    @test sinfo.cpuids_numa[6] == 80:95
    @test sinfo.cpuids_numa[7] == 96:111
    @test sinfo.cpuids_numa[8] == 112:127
    @test sinfo.ishyperthread == falses(128)
    @test sinfo.cpuids_core == [[i] for i in 0:127]
end

@testset "lscpu2sysinfo (NOCTUA1)" begin
    sinfo = ThreadPinning.lscpu2sysinfo(ThreadPinning.lscpu_NOCTUA1)
    @test typeof(sinfo) == ThreadPinning.SysInfo
    @test sinfo.ncores == 40
    @test sinfo.nsockets == 2
    @test sinfo.nnuma == 2
    @test sinfo.hyperthreading == false
    @test sinfo.cpuids == 0:39
    @test length(sinfo.cpuids_sockets) == 2
    @test sinfo.cpuids_sockets[1] == 0:19
    @test sinfo.cpuids_sockets[2] == 20:39
    @test length(sinfo.cpuids_numa) == 2
    @test sinfo.cpuids_numa[1] == 0:19
    @test sinfo.cpuids_numa[2] == 20:39
    @test sinfo.ishyperthread == falses(40)
    @test sinfo.cpuids_core == [[i] for i in 0:39]
end

@testset "lscpu2sysinfo (FUGAKU)" begin
    sinfo = ThreadPinning.lscpu2sysinfo(ThreadPinning.lscpu_FUGAKU)
    @test typeof(sinfo) == ThreadPinning.SysInfo
    @test sinfo.ncores == 50
    @test sinfo.nsockets == 1
    @test sinfo.nnuma == 6
    @test sinfo.hyperthreading == false
    @test sinfo.cpuids == vcat([0, 1], 12:59)
    @test length(sinfo.cpuids_sockets) == 1
    @test sinfo.cpuids_sockets[1] == sinfo.cpuids
    @test length(sinfo.cpuids_numa) == 6
    @test sinfo.cpuids_numa[1] == [0]
    @test sinfo.cpuids_numa[2] == [1]
    @test sinfo.cpuids_numa[3] == 12:23
    @test sinfo.cpuids_numa[4] == 24:35
    @test sinfo.cpuids_numa[5] == 36:47
    @test sinfo.cpuids_numa[6] == 48:59
    @test sinfo.ishyperthread == falses(50)
    @test sinfo.cpuids_core == [[0], [1], [12], [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30], [31], [32], [33], [34], [35], [36], [37], [38], [39], [40], [41], [42], [43], [44], [45], [46], [47], [48], [49], [50], [51], [52], [53], [54], [55], [56], [57], [58], [59]]
end

@testset "lscpu2sysinfo (Ookami ThunderX2)" begin
    sinfo = ThreadPinning.lscpu2sysinfo(ThreadPinning.lscpu_OokamiThunderX2)
    @test typeof(sinfo) == ThreadPinning.SysInfo
    @test sinfo.ncores == 64
    @test sinfo.nsockets == 2
    @test sinfo.nnuma == 2
    @test sinfo.hyperthreading == true
    @test sinfo.cpuids == 0:255
    @test length(sinfo.cpuids_sockets) == 2
    @test length(sinfo.cpuids_numa) == 2
    @test sinfo.cpuids_numa[1] == 0:127
    @test sinfo.cpuids_numa[2] == 128:255
    @test sinfo.ishyperthread == vcat(falses(32), trues(96), falses(32), trues(96))
    @test sinfo.cpuids_core == [[0, 32, 64, 96], [1, 33, 65, 97], [2, 34, 66, 98], [3, 35, 67, 99], [4, 36, 68, 100], [5, 37, 69, 101], [6, 38, 70, 102], [7, 39, 71, 103], [8, 40, 72, 104], [9, 41, 73, 105], [10, 42, 74, 106], [11, 43, 75, 107], [12, 44, 76, 108], [13, 45, 77, 109], [14, 46, 78, 110], [15, 47, 79, 111], [16, 48, 80, 112], [17, 49, 81, 113], [18, 50, 82, 114], [19, 51, 83, 115], [20, 52, 84, 116], [21, 53, 85, 117], [22, 54, 86, 118], [23, 55, 87, 119], [24, 56, 88, 120], [25, 57, 89, 121], [26, 58, 90, 122], [27, 59, 91, 123], [28, 60, 92, 124], [29, 61, 93, 125], [30, 62, 94, 126], [31, 63, 95, 127], [128, 160, 192, 224], [129, 161, 193, 225], [130, 162, 194, 226], [131, 163, 195, 227], [132, 164, 196, 228], [133, 165, 197, 229], [134, 166, 198, 230], [135, 167, 199, 231], [136, 168, 200, 232], [137, 169, 201, 233], [138, 170, 202, 234], [139, 171, 203, 235], [140, 172, 204, 236], [141, 173, 205, 237], [142, 174, 206, 238], [143, 175, 207, 239], [144, 176, 208, 240], [145, 177, 209, 241], [146, 178, 210, 242], [147, 179, 211, 243], [148, 180, 212, 244], [149, 181, 213, 245], [150, 182, 214, 246], [151, 183, 215, 247], [152, 184, 216, 248], [153, 185, 217, 249], [154, 186, 218, 250], [155, 187, 219, 251], [156, 188, 220, 252], [157, 189, 221, 253], [158, 190, 222, 254], [159, 191, 223, 255]]
    @test length.(sinfo.cpuids_core) == fill(4, 64)
end

@testset "lscpu2sysinfo (i912900H)" begin
    sinfo = ThreadPinning.lscpu2sysinfo(ThreadPinning.lscpu_i912900H)
    @test typeof(sinfo) == ThreadPinning.SysInfo
    @test sinfo.nsockets == 1
    @test sinfo.nnuma == 1
    @test sinfo.hyperthreading == true
    @test sinfo.cpuids == 0:19
    @test length(sinfo.cpuids_sockets) == 1
    @test sinfo.cpuids_sockets[1] == 0:19
    @test length(sinfo.cpuids_numa) == 1
    @test sinfo.cpuids_numa[1] == 0:19
    @test sinfo.ishyperthread == Bool[0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
end

@testset "update_sysinfo" begin
    @test isnothing(ThreadPinning.update_sysinfo!())
    nsockets_before = nsockets()
    @test isnothing(ThreadPinning.update_sysinfo!(; clear=true))
    @test nsockets() == 1
    @test isnothing(ThreadPinning.update_sysinfo!())
    @test nsockets() == nsockets_before
end
