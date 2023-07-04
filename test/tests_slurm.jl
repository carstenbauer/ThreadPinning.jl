include("common.jl")
using Test
using ThreadPinning

@testset "SLURM" begin
    withenv("SLURM_JOBID"=>nothing) do
        @test !ThreadPinning.SLURM.isslurmjob()
    end
    withenv("SLURM_JOBID"=>"12345") do
        @test ThreadPinning.SLURM.isslurmjob()
    end

    # get_cpu_mask[_str]()
    withenv("SLURM_CPU_BIND"=>"verbose,mask_cpu:0x000000000000000000000001FFFFFFFF", "SLURM_CPU_BIND_LIST"=>nothing) do
        @test ThreadPinning.SLURM.get_cpu_mask_str() == "0x000000000000000000000001FFFFFFFF"
        @test ThreadPinning.SLURM.get_cpu_mask() == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
    withenv("SLURM_CPU_BIND_LIST"=>"0x000000000000000000000001FFFFFFFF", "SLURM_CPU_BIND"=>nothing) do
        @test ThreadPinning.SLURM.get_cpu_mask_str() == "0x000000000000000000000001FFFFFFFF"
        @test ThreadPinning.SLURM.get_cpu_mask() == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    # ncpus_per_task()
    withenv("SLURM_CPUS_PER_TASK"=>"21") do
        @test ThreadPinning.SLURM.ncpus_per_task() == 21
    end
    withenv("SLURM_CPUS_PER_TASK"=>nothing, "SLURM_CPU_BIND_LIST"=>nothing, "SLURM_CPU_BIND"=>nothing) do
        @test ThreadPinning.SLURM.ncpus_per_task() == 0
    end
end
