using ThreadPinning
using Test

@testset "Preferences" begin
    @test isnothing(ThreadPinning.Prefs.set_autoupdate(false))
    @test ThreadPinning.Prefs.get_autoupdate() == false
    @test isnothing(ThreadPinning.Prefs.set_autoupdate(true))

    @test isnothing(ThreadPinning.Prefs.showall())

    @test ThreadPinning.Prefs.has_autoupdate()
    @test isnothing(ThreadPinning.Prefs.clear())
    @test !ThreadPinning.Prefs.has_autoupdate()
end
