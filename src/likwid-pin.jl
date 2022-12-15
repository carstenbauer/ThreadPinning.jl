function pinthreads(str::AbstractString)
    if !contains(str, ':')
        # explicit list
        pinthreads(_explicit2cpuids(str))
    else
        #TODO
    end
    return nothing
end

function _explicit2cpuids(str)
    sections = split(str, ',')
    cpuids = Int64[]
    for s in sections
        if contains(s, '-')
            r = parse.(Int64, split(s, '-'))
            append!(cpuids, r[1]:r[2])
        else
            id = parse(Int64, s)
            push!(cpuids, id)
        end
    end
    return cpuids
end

function _domain2cpuids(str)

end
