const IID = 1
const IOSID = 2
const ICORE = 3
const INUMA = 4
const ISOCKET = 5
const ISMT = 6

# # lscpu parsing
# function update_sysinfo!(; fromscratch = false, lscpustr = nothing,
#                          clear = false)
#     if clear
#         SYSINFO[] = SysInfo()
#     else
#         local sysinfo
#         try
#             if !isnothing(lscpustr)
#                 # explicit lscpu string given
#                 sysinfo = lscpu2sysinfo(lscpustr)
#             else
#                 if !fromscratch
#                     # use precompiled lscpu string
#                     sysinfo = lscpu2sysinfo(LSCPU_STRING)
#                 else
#                     # from scratch: query lscpu again
#                     sysinfo = lscpu2sysinfo(lscpu_string())
#                 end
#             end
#         catch err
#             throw(ArgumentError("Couldn't parse the given lscpu string:\n\n $lscpustr \n\n"))
#         end
#         SYSINFO[] = sysinfo
#     end
#     return nothing
# end
