using ThreadPinning
using MPI

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

pinthreads_mpi(:sockets, rank, nranks)

sleep(0.1*rank)
@show getcpuids()
