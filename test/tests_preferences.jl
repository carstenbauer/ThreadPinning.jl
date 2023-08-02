using ThreadPinning
using Test

@testset "Preferences" begin
    @test isnothing(ThreadPinning.Prefs.set_autoupdate(false))
    @test ThreadPinning.Prefs.get_autoupdate() == false
    @test isnothing(ThreadPinning.Prefs.set_autoupdate(true))

    @test isnothing(ThreadPinning.Prefs.set_os_warning(false))
    @test ThreadPinning.Prefs.get_os_warning() == false
    @test isnothing(ThreadPinning.Prefs.set_os_warning(true))

    @test isnothing(ThreadPinning.Prefs.set_pin(:sockets))
    @test ThreadPinning.Prefs.get_pin() == "sockets"
    @test isnothing(ThreadPinning.Prefs.set_pin("cores"))
    @test ThreadPinning.Prefs.get_pin() == "cores"

    @test isnothing(ThreadPinning.Prefs.set_likwidpin("S:scatter"))
    @test ThreadPinning.Prefs.get_likwidpin() == "S:scatter"

    @test isnothing(ThreadPinning.Prefs.showall())

    @test ThreadPinning.Prefs.has_autoupdate()
    @test ThreadPinning.Prefs.has_pin()
    @test ThreadPinning.Prefs.has_likwidpin()
    @test isnothing(ThreadPinning.Prefs.clear())
    @test !ThreadPinning.Prefs.has_autoupdate()
    @test !ThreadPinning.Prefs.has_pin()
    @test !ThreadPinning.Prefs.has_likwidpin()
end
