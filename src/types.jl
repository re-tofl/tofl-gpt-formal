mutable struct Term
    name::String
    childs::Vector{Term}
end

function term_to_string(term)
    if isempty(term.childs)
        term.name
    else
        child_strings = [term_to_string(child) for child in term.childs]
        "$(term.name)(" * join(child_strings, ", ") * ")"
    end
end
