using ThreadPinning
using Test

@testset "Preferences" begin
    @test isnothing(ThreadPinning.Prefs.set_pinning(:spread))
    @test isnothing(ThreadPinning.Prefs.set_places(:numa))

    @test ThreadPinning.Prefs.get_pinning() == :spread
    @test ThreadPinning.Prefs.get_places() == :numa

    @test_throws ArgumentError ThreadPinning.Prefs.set_pinning(:asd)
    @test_throws ArgumentError ThreadPinning.Prefs.set_places(:asd)

    @test isnothing(ThreadPinning.Prefs.set_autoupdate(false))
    @test ThreadPinning.Prefs.get_autoupdate() == false
    @test isnothing(ThreadPinning.Prefs.set_autoupdate(true))

    @test isnothing(ThreadPinning.Prefs.showall())

    @test ThreadPinning.Prefs.has_pinning()
    @test ThreadPinning.Prefs.has_places()
    @test ThreadPinning.Prefs.has_autoupdate()
    @test isnothing(ThreadPinning.Prefs.clear())
    @test !ThreadPinning.Prefs.has_pinning()
    @test !ThreadPinning.Prefs.has_places()
    @test !ThreadPinning.Prefs.has_autoupdate()
end
