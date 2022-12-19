"""
Pins Julia threads to CPU threads based on the given `likwid-pin` compatible string.
Checkout the [LIKWID documentation](https://github.com/RRZE-HPC/likwid/wiki/Likwid-Pin)
for more information.

If the keyword argument `onebased` is set to `true`, logical indices as well as domain
indices start at one instead of zero (likwid-pin default). Note, though, that this doesn't
affect the explicit pinning mode where "physical" CPU IDs always start at zero.

**Examples**
* `pinthreads_likwidpin("S0:0-3")`
* `pinthreads_likwidpin("M1:0,2,4")`
* `pinthreads_likwidpin("S:scatter")`
* `pinthreads_likwidpin("E:N:4:1:2")`
"""
function pinthreads_likwidpin(str::AbstractString; onebased = false)
    cpuids = likwidpin_to_cpuids(str; onebased)
    @debug "CPU IDs" cpuids
    pinthreads(cpuids)
end

"""
Convert the given likwid-pin compatible string into a CPU ID list.
"""
function likwidpin_to_cpuids(lpstr::AbstractString; onebased = false)
    blocks = split(lpstr, '@')
    blocks_cpuids = Vector{Vector{Int}}(undef, length(blocks))
    for (i, block_str) in pairs(blocks)
        sections = split(block_str, ':')
        if length(sections) == 1 # no colon
            @debug "likwid-pin: explicit"
            cpuids = _lp_explicit2numbers(sections[1])
        else
            if sections[1] == "E"
                @debug "likwid-pin: expression"
                cpuids = _lp_expression2cpuids(sections; onebased)
            else
                @debug "likwid-pin: domain-based"
                cpuids = _lp_domainbased2cpuids(sections; onebased)
            end
        end
        blocks_cpuids[i] = cpuids
    end
    return reduce(vcat, blocks_cpuids)
end

function _lp_explicit2numbers(str)
    sections = split(str, ',')
    numbers = Int64[]
    for s in sections
        if contains(s, '-')
            substrs = split(s, '-')
            if isempty(substrs[1])
                throw(ArgumentError("Illegal number or range. Maybe a negative CPU ID?"))
            else
                r = parse.(Int64, substrs)
                append!(numbers, r[1]:r[2])
            end
        else
            id = parse(Int64, s)
            push!(numbers, id)
        end
    end
    return numbers
end

function _lp_domainbased2cpuids(sections; onebased = false)
    @assert length(sections) > 1
    domain = sections[1]
    _lp_check_domain(domain; onebased)
    policy = sections[2]
    # TODO "balanced" and "cbalanced" policies
    if policy == "scatter"
        numthreads = length(sections) > 2 ? parse(Int, sections[3]) : Threads.nthreads()
        cpuids = _lp_scatter_cpuids(domain, numthreads; onebased)
    else
        idcs = _lp_explicit2numbers(policy) # logical indices, starting at 0(!)
        cpuids = _lp_domain_cpuids(domain, idcs; onebased)
    end
    return cpuids
end

function _lp_expression2cpuids(sections; onebased = false)
    @assert sections[1] == "E"
    if length(sections) == 3 || length(sections) == 5
        domain = sections[2]
        _lp_check_domain(domain; onebased)
        numthreads = parse(Int, sections[3])
        if length(sections) == 5
            chunk_size = parse(Int, sections[4])
            stride = parse(Int, sections[5])
        else
            chunk_size = 1
            stride = 1
        end
        _lp_expression_cpuids(domain, numthreads, chunk_size, stride; onebased)
    else
        throw(ArgumentError("Unknown expression format. Allowed syntax is " *
                            "\"E:domain:nthreads[:chunk_size:stride]\"."))
    end
end

function _lp_check_domain(domain; onebased = false)
    if !_lp_is_valid_domain(domain; onebased)
        throw(ArgumentError("Unknown domain \"$domain\". Valid domains are " *
                            "$(likwidpin_domains(; onebased))."))
    end
    return nothing
end

"""
The likwid-pin compatible domains that are available for the system.
"""
function likwidpin_domains(; onebased = false)
    # ('N','S','D','M','C')
    domains = ["N", "S", "M"]
    append!(domains, ["S$i" for i in (0 + onebased):(nsockets() - !onebased)])
    append!(domains, ["M$i" for i in (0 + onebased):(nnuma() - !onebased)])
    # append!(domains, ["D$i" for i in TODO()])
    # append!(domains, ["C$i" for i in TODO()])
    return domains
end

function _lp_is_valid_domain(domain::AbstractString; kwargs...)
    domain in likwidpin_domains(; kwargs...)
end
function _lp_is_valid_domain(domain::Symbol; kwargs...)
    _lp_is_valid_domain(string(domain); kwargs...)
end

function _lp_scatter_cpuids(domain, numthreads; onebased = false)
    offset = onebased ? 0 : 1
    if domain == "N"
        domain_cpuids = cpuids_per_node()
    elseif domain == "S"
        domain_cpuids = interweave(cpuids_per_socket()...)
    elseif domain == "M"
        domain_cpuids = interweave(cpuids_per_numa()...)
    elseif startswith(domain, "S")
        socketid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_socket()[socketid + offset]
    elseif startswith(domain, "M")
        numaid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_numa()[numaid + offset]
    else
        throw(ArgumentError("Don't know how to handle domain \"$domain\" in " *
                            "domain:scatter mode."))
    end

    # if length(domain_cpuids) >= numthreads
    cpuids = domain_cpuids[mod1.(1:numthreads, length(domain_cpuids))]
    # else
    #     throw(ArgumentError("Not enough CPU threads. Trying to pin $numthreads Julia " *
    #                         "threads but there are only $(length(domain_cpuids)) CPU " *
    #                         "threads available given the domain + scattering policy."))
    # end
    return cpuids
end

function _lp_domain_cpuids(domain, lp_idcs; onebased = false)
    offset = onebased ? 0 : 1
    idcs = lp_idcs .+ offset
    if domain == "N"
        domain_cpuids = cpuids_per_node()
    elseif startswith(domain, "S") && length(domain) > 1
        socketid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_socket()[socketid + offset]
    elseif startswith(domain, "M") && length(domain) > 1
        numaid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_numa()[numaid + offset]
    else
        throw(ArgumentError("Don't know how to handle domain \"$domain\" in " *
                            "domain:explicit mode."))
    end

    if length(domain_cpuids) < length(idcs)
        throw(ArgumentError("Not enough CPU threads in domain. Specified $(length(idcs)) " *
                            "indices but domain \"$domain\" only has " *
                            "$(length(domain_cpuids)) CPU threads."))
    else
        if checkbounds(Bool, domain_cpuids, idcs)
            @inbounds cpuids = domain_cpuids[idcs]
        else
            throw(ArgumentError("Invalid logical CPU indices provided for domain " *
                                "\"domain\". Valid range: $(0 + onebased) to " *
                                "$(length(domain_cpuids)-offset)."))
        end
    end
    return cpuids
end

function _lp_expression_cpuids(domain, numthreads, chunk_size, stride; onebased)
    # Note: compact order!
    offset = onebased ? 0 : 1
    if domain == "N"
        domain_cpuids = cpuids_per_node(; compact = true)
    elseif startswith(domain, "S") && length(domain) > 1
        socketid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_socket(; compact = true)[socketid + offset]
    elseif startswith(domain, "M") && length(domain) > 1
        numaid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_numa(; compact = true)[numaid + offset]
    else
        throw(ArgumentError("Don't know how to handle domain \"$domain\" in expression."))
    end

    if length(domain_cpuids) < numthreads
        throw(ArgumentError("Not enough CPU threads in domain. Specified $(numthreads) " *
                            "for the number of threads but domain \"$domain\" only has " *
                            "$(length(domain_cpuids)) CPU threads."))
    else
        if chunk_size == stride == 1
            @inbounds cpuids = domain_cpuids[1:numthreads]
        else
            # chunk size + stride case
            @debug "E:numthreads:chunk_size:stride" numthreads chunk_size stride
            nchunks, rem = divrem(numthreads, chunk_size)
            if rem != 0
                throw(ArgumentError("Ratio of given number of threads ($numthreads) and " *
                                    "chunk size ($chunk_size) must be integer."))
            end
            stride_range = range(start = 1, step = stride, stop = nchunks * stride)
            if last(stride_range) + chunk_size - 1 > length(domain_cpuids)
                throw(ArgumentError("Not enough CPU threads in domain. Combination of " *
                                    "stride and chunk_size exceeds the number of CPU " *
                                    "threads ($(length(domain_cpuids))) in the domain " *
                                    "\"$domain\"."))
            end
            cpuids = Vector{Int}(undef, numthreads)
            i = 1
            for s in stride_range
                for c in 0:(chunk_size - 1)
                    cpuids[i] = domain_cpuids[s + c]
                    i += 1
                end
            end
            return cpuids
        end
    end
    return cpuids
end
