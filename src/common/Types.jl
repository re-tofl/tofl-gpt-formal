# parser/Types.jl
module Types

export Term, term_to_string

struct Term
    name::String
    childs::Vector{Term}
end

# Функция для отображения терма в строку
function term_to_string(term::Term)
    if isempty(term.childs)
        return term.name
    else
        child_strings = [term_to_string(child) for child in term.childs]
        return "$(term.name)(" * join(child_strings, ", ") * ")"
    end
end

end # module Types
