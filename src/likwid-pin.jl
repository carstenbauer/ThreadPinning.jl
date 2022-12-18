function pinthreads(str::AbstractString)
    cpuids = likwidpin_to_cpuids(str)
    @debug "CPU IDs" cpuids
    pinthreads(cpuids)
end

function likwidpin_to_cpuids(str::AbstractString)
    sections = split(str, ':')
    if length(sections) == 1 # no colon
        @debug "likwid-pin: explicit"
        cpuids = _explicit2numbers(sections[1])
    else
        if sections[1] == "E"
            @debug "likwid-pin: expression"
            # TODO
        else
            @debug "likwid-pin: domain-based"
            cpuids = _domainbased2cpuids(sections)
        end
    end
    return cpuids
end

function _explicit2numbers(str)
    sections = split(str, ',')
    numbers = Int64[]
    for s in sections
        if contains(s, '-')
            r = parse.(Int64, split(s, '-'))
            append!(numbers, r[1]:r[2])
        else
            id = parse(Int64, s)
            push!(numbers, id)
        end
    end
    return numbers
end

function _domainbased2cpuids(sections)
    @assert length(sections) > 1
    domain = sections[1]
    if !is_valid_likwidpin_domain(domain)
        throw(ArgumentError("Unknown domain \"$domain\". Valid domains are $(likwidpin_domains())."))
    end
    policy = sections[2]
    if policy == "scatter"
        numthreads = length(sections) > 2 ? parse(Int, sections[3]) : Threads.nthreads()
        cpuids = _likwidpin_scatter_cpuids(domain, numthreads)
    else
        idcs = _explicit2numbers(policy) # logical indices, starting at 0(!)
        cpuids = _likwidpin_domain_cpuids(domain, idcs)
    end
    return cpuids
end

function likwidpin_domains()
    # ('N','S','D','M','C')
    domains = ["N", "S", "M"]
    append!(domains, ["S$i" for i in 0:(nsockets() - 1)])
    append!(domains, ["M$i" for i in 0:(nnuma() - 1)])
    # append!(domains, ["D$i" for i in TODO()])
    # append!(domains, ["C$i" for i in TODO()])
    return domains
end

is_valid_likwidpin_domain(domain::AbstractString) = domain in likwidpin_domains()
is_valid_likwidpin_domain(domain::Symbol) = is_valid_likwidpin_domain(string(domain))

function _likwidpin_scatter_cpuids(domain, numthreads)
    if domain == "N"
        domain_cpuids = cpuids_per_node()
    elseif domain == "S"
        domain_cpuids = reduce(interweave, cpuids_per_socket())
    elseif domain == "M"
        domain_cpuids = reduce(interweave, cpuids_per_numa())
    elseif startswith(domain, "S")
        socketid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_socket()[socketid + 1]
    elseif startswith(domain, "M")
        numaid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_numa()[numaid + 1]
    else
        error("Don't know how to handle domain \"$domain\" in domain:scatter[:numthreads] mode.")
    end

    if length(domain_cpuids) >= numthreads
        @inbounds cpuids = domain_cpuids[1:numthreads]
    else
        error("Not enough CPU threads. Trying to pin $numthreads Julia threads but there are only $(length(domain_cpuids)) CPU threads available given the domain + scattering policy.")
    end
    return cpuids
end

function _likwidpin_domain_cpuids(domain, lp_idcs)
    idcs = lp_idcs .+ 1 # zero- to one-based
    if domain == "N"
        domain_cpuids = cpuids_per_node()
    elseif startswith(domain, "S") && length(domain) > 1
        socketid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_socket()[socketid + 1]
    elseif startswith(domain, "M") && length(domain) > 1
        numaid = parse(Int, domain[2:end])
        domain_cpuids = cpuids_per_numa()[numaid + 1]
    else
        error("Don't know how to handle domain \"$domain\" in domain:explicit mode.")
    end

    if length(domain_cpuids) < length(idcs)
        error("Not enough CPU threads in domain. Specified $(length(idcs)) indices but domain \"$domain\" only has $(length(domain_cpuids)) CPU threads.")
    else
        if checkbounds(Bool, domain_cpuids, idcs)
            @inbounds cpuids = domain_cpuids[idcs]
        else
            error("Invalid logical CPU indices provided for domain \"domain\". Valid range: 0 to $(length(domain_cpuids)-1).")
        end
    end
    return cpuids
end
