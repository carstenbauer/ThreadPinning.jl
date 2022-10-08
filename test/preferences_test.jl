using ThreadPinning
using Test

@testset "Preferences" begin
    @test isnothing(ThreadPinning.Prefs.set_pinning(:spread))
    @test isnothing(ThreadPinning.Prefs.set_places(:numa))

    @test ThreadPinning.Prefs.get_pinning() == :spread
    @test ThreadPinning.Prefs.get_places() == :numa

    @test_throws ArgumentError ThreadPinning.Prefs.set_pinning(:asd)
    @test_throws ArgumentError ThreadPinning.Prefs.set_places(:asd)

    @test ThreadPinning.Prefs.has_pinning()
    @test ThreadPinning.Prefs.has_places()
    @test isnothing(ThreadPinning.Prefs.clear())
    @test !ThreadPinning.Prefs.has_pinning()
    @test !ThreadPinning.Prefs.has_places()
end
