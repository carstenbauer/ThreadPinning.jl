# OMP_PLACES
function _omp_places_env_parse(places::AbstractString)::Vector{Vector{Int}}
    if places == "threads"
        return [cpuids_all()]
    elseif places == "sockets"
        return cpuids_per_socket()
    elseif places == "cores"
        return [filter(!ishyperthread, cpuids_all())]
    end

    # TODO: support "threads(3)" etc. limiting the number of places

    if contains(places, ',')
        curly_braces_contents = [last(x)
                                 for x in split.(split(places, '}'), '{')
                                 if !isempty(last(x))]
        places_jl = _omp_curly_braces_content_to_jl.(curly_braces_contents)
        return places_jl
    end
end

function _omp_curly_braces_content_to_jl(content::AbstractString)
    if contains(content, ':')
        _omp_range_to_jl_array(content)
    elseif contains(content, ',')
        _omp_list_to_jl_array(content)
    else
        throw(ArgumentError("Input \"$content\" isn't in OMP-style."))
    end
end

function _omp_list_to_jl_array(list::AbstractString)
    # contains(list, ',') || throw(ArgumentError("Input list $list isn't OMP style."))
    nums = parse.(Int, split(list, ','))
    return nums
end

function _omp_range_to_jl_array(range::AbstractString)
    # contains(range, ':') || throw(ArgumentError("Input range $range isn't OMP style."))
    num_strs = split(range, ':')
    if length(num_strs) == 2 && !contains(first(num_strs), '{')
        nums = parse.(Int, num_strs)
        return @inbounds collect(nums[1]:(nums[1] + nums[2] - 1))
    else
        throw(ArgumentError("Not a supported OMP-style range."))
    end
end

# OMP_PROC_BIND
function _omp_proc_bind_env_parse(bind::AbstractString)::Union{Nothing, Symbol}
    bindl = lowercase(bind)
    if bindl == "false"
        return nothing # don't pin threads at all
    elseif bindl == "master"
        throw(ArgumentError("Binding option \"master\" isn't supported."))
    elseif bindl == "close"
        return :close
    elseif bindl == "spread"
        return :spread
    else
        throw(ArgumentError("Unknown binding option \"$bind\"."))
    end
end
