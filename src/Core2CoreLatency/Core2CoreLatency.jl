module Core2CoreLatency

using ..ThreadPinning: pinthread, pinthreads, getcpuids, @tspawnat

const State = Int
const Preparing = 0
const Ready = 1
const Ping = 2
const Pong = 3
const Finish = 4

Base.@kwdef struct Sync
    state::Threads.Atomic{State} = Threads.Atomic{State}(Preparing)
end

state(S::Sync) = S.state[]
function wait_until(S::Sync, expected_state::State)
    while state(S) != expected_state
    end
    return nothing
end
function set(S::Sync, state::State)
    S.state[] = state
    return nothing
end
function wait_as_long_as(S::Sync, wait_state::State)
    loaded_state = state(S)
    while loaded_state == wait_state
        loaded_state = state(S)
    end
    return loaded_state
end

function run_bench(cpu1::Integer, cpu2::Integer; nsamples::Integer = 100,
                   mode::Symbol = :min)
    cpu1 == cpu2 && return zero(Float64)
    Threads.nthreads() >= 2 || @error("Need at least two Julia threads.")

    S = Sync()
    pinthread(cpu1)

    second_thread = @tspawnat 2 begin
        pinthread(cpu2)
        set(S, Ready)

        state = wait_as_long_as(S, Ready)
        while state != Finish
            if state == Ping
                set(S, Pong)
                state = wait_as_long_as(S, Pong)
            end
        end
    end

    wait_until(S, Ready)

    Δts = zeros(typeof(time_ns()), nsamples)
    @inbounds for i in 1:nsamples
        Δts[i] = begin
            t = time_ns()
            set(S, Ping)
            wait_until(S, Pong)
            time_ns() - t
        end
    end

    if mode == :avg
        Δt = sum(Float64, Δts) / nsamples
    elseif mode == :min || mode == :minimum
        Δt = Float64(minimum(Δts))
    else
        throw(ArgumentError("Unkown mode $mode."))
    end

    set(S, Finish)
    fetch(second_thread)
    return Δt
end

end # module
