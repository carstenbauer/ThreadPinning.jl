using Test
using ThreadPinning

@testset "gather_sysinfo_lscpu (NOCTUA2LOGIN)" begin
    sinfo = ThreadPinning.gather_sysinfo_lscpu(ThreadPinning.lscpu_NOCTUA2LOGIN)
    @test typeof(sinfo) == ThreadPinning.SysInfo
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
end

@testset "gather_sysinfo_lscpu (NOCTUA2)" begin
    sinfo = ThreadPinning.gather_sysinfo_lscpu(ThreadPinning.lscpu_NOCTUA2)
    @test typeof(sinfo) == ThreadPinning.SysInfo
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
end

@testset "gather_sysinfo_lscpu (NOCTUA1)" begin
    sinfo = ThreadPinning.gather_sysinfo_lscpu(ThreadPinning.lscpu_NOCTUA1)
    @test typeof(sinfo) == ThreadPinning.SysInfo
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
end

@testset "gather_sysinfo_lscpu (FUGAKU)" begin
    sinfo = ThreadPinning.gather_sysinfo_lscpu(ThreadPinning.lscpu_FUGAKU)
    @test typeof(sinfo) == ThreadPinning.SysInfo
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
end

@testset "update_sysinfo" begin
    nsockets_before = nsockets()
    @test isnothing(ThreadPinning.update_sysinfo!(; clear=true))
    @test nsockets() == 1
    @test isnothing(ThreadPinning.update_sysinfo!())
    @test nsockets() == nsockets_before
end
