# Pinning Julia Tasks

## Task-based multithreading
It is important to note that Julia implements **task-based multithreading**: `M` dynamically created user tasks get scheduled onto `N` Julia threads. By default, task scheduling is dynamic and is handled by Julia's built-in scheduler. Similar to how the operating system's scheduler can freely move Julia threads between CPU threads, Julia's scheduler can move tasks between Julia threads. Consequently, before pinning, a user cannot reliably predict on which Julia thread a task will run and on which CPU thread a Julia thread will run (see the visualization below).



![tasks_threads_cores](tasks_threads_cores.svg)



The primary purpose of ThreadPinning.jl is to allow you to pin Julia threads to CPU-threads. In this sense, it enables you to supersede the dynamic OS scheduler (right part in the image above). However, the dynamic scheduling of Julia tasks (left part in the image above) remains as is.

## Static scheduling and *sticky* tasks

If you want to opt-out of Julia's dynamic task scheduling and want to "pin" Julia tasks to specific Julia threads, you will often need to use tools from external libraries (such as ThreadPinning.jl), as support for this in base Julia is sparse. The only official API for static scheduling of *sticky* tasks (i.e. tasks that stay on the Julia thread they've been spawned on) is [`Threads.@threads :static`](https://docs.julialang.org/en/v1/base/multi-threading/#Base.Threads.@threads). In code like

```julia
Threads.@threads for i in 1:Threads.nthreads()
    do_something_on_thread(i)
end
```

it is guaranteed that each Julia thread will run precisely one *sticky* task that corresponds to one iteration of the loop. Hence, `i` may be interpreted as a Julia thread index. In fact, it is even guaranteed that the first (default) Julia thread will run the first task (iteration), the second (default) Julia thread will run the second task (iteration), and so on.

!!! warning
    Beware, the indices of the *default* Julia threads (as given by `Threads.threadid()` if called on them) actually only start at 1 in the absence of *interactive* threads.

!!! warning
    Under the hood, `Threads.@threads` always splits up the iteration regime into `Threads.nthreads()` many tasks, irrespective of the length of the iteration range. In the example above, there is a one-to-one correspondence between iterations and tasks but for general iterations (say, `1:N` where `N > Threads.nthreads()`) a task - and consequently a Julia thread - will take care of more than one iteration.

The static scheduling option `Threads.@threads :static` is the only official built-in way to get sticky tasks. In particular, there is no sticky pendant of `@spawn` for manually creating tasks.

ThreadPinning.jl aims to fill this gap by providing [`ThreadPinning.@spawnat`](@ref api_stabletasks) and a few other tools. As the name suggests, this macro allows you to spawn a *sticky* task on a specific Julia thread, e.g. `ThreadPinning.@spawnat 3 println("Hello from thread 3")`.

Using `ThreadPinning.@spawnat` we can rewrite the code above as

```julia
@sync for i in 1:Threads.nthreads()
    ThreadPinning.@spawnat i do_something_on_thread(i)
end
```

Both the task-iteration mapping and the task-thread assignment are explicitly and immediately visible here.
