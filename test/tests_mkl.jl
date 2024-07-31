include("common.jl")
using ThreadPinning
using Test
using MKL

@testset "MKL utilities" begin
    @test ThreadPinning.MKL.mkl_is_loaded()
    @test ThreadPinning.MKL.mkl_get_dynamic() isa Integer
    @test isnothing(ThreadPinning.MKL.mkl_set_dynamic(1))
    @test ThreadPinning.MKL.mkl_get_dynamic() == 1
    @test isnothing(ThreadPinning.MKL.mkl_set_dynamic(0))
    @test ThreadPinning.MKL.mkl_get_dynamic() == 0
end

@testset "MKL threadinfo" begin
    @test isnothing(threadinfo())
    @test isnothing(threadinfo(; blas = true, hints = true))
end
