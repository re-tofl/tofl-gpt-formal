include("common/Types.jl")
include("parser/parse_TRS_and_apply_interpretations.jl")

using .Types
using .Parser
using Random
using JSON

export generate_random_term, rewrite_term

function collect_vars(term)
    result = Set()
    inner_collect_vars = (term) -> begin
        if isempty(term.childs)
            push!(result, term.name)
        else
            foreach(inner_collect_vars, term.childs)
        end
    end
    inner_collect_vars(term)
    result
end

function replace_random_leaf(tree, new_term)
    # Function to collect all leaves in the tree
    function collect_leaves(node, leaves)
        if isempty(node.childs)
            push!(leaves, node)
        else
            for child in node.childs
                collect_leaves(child, leaves)
            end
        end
    end

    # Collect all leaves
    leaves = Vector()
    collect_leaves(tree, leaves)

    # Check if there are leaves to replace
    if isempty(leaves)
        error("The tree has no leaves to replace.")
    end

    # Select a random leaf
    random_leaf = rand(leaves)

    # Replace the random leaf with the new term
    function replace_leaf(node)
        if node ≡ random_leaf
            return new_term
        else
            for i in 1:length(node.childs)
                node.childs[i] = replace_leaf(node.childs[i])
            end
            return node
        end
    end

    return replace_leaf(tree)
end

function build_example_term(term_pairs)
    random_left_part = () -> term_pairs[rand(1:length(term_pairs))][1]
    root = random_left_part()
    for _ = 1:length(term_pairs)
        root = replace_random_leaf(root, random_left_part)
    end
    root
end

function rewrite_term()
    
end

# function check_counterexample(term_pairs, interpretations, var_map)
#     for pair ∈ term_pairs
#         left = Parser.apply_interpretation(pair[1], interpretations)
#         right = Parser.apply_interpretation(pair[2], interpretations)
#         for (var, value) ∈ var_map
#             left = replace(left, var => value)
#             right = replace(right, var => value)
#         end
#         if eval(Meta.parse("$left <= $right"))
#             variables = collect_vars(pair[1]) ∪ collect_vars(pair[2])
#             var_string = ""
#             for v ∈ variables
#                 var_string *= "$v = $(var_map[v])\n"
#             end
#             return """
#             Переданный набор интерпретаций не доказывает завершаемость $(Types.term_to_string(pair[1])) -> $(Types.term_to_string(pair[2]))
#             $var_string
#             При подстановке вышеуказанных чисел получаем $(eval(Meta.parse(left))) -> $(eval(Meta.parse(right)))
#             """
#         end
#     end
# end

# # Функция для генерации терма, который может быть переписан по правилам TRS
# function generate_random_term(trs_rules::Vector{<:Dict})
#     # Выбираем случайное правило из TRS
#     rule = rand(trs_rules)
#     left_pattern = rule["left"]

#     # Генерируем терм на основе левой части правила
#     term = generate_term_from_pattern(left_pattern)
#     return term
# end

# # Рекурсивная функция для генерации терма на основе шаблона
# function generate_term_from_pattern(pattern::Dict)
#     func_name = pattern["value"]
#     childs = Term[]
#     for child_pattern in pattern["childs"]
#         # Решаем, подставить переменную или функцию
#         if isempty(child_pattern["childs"])
#             # Генерируем переменную
#             var_name = generate_variable_name(child_pattern["value"])
#             push!(childs, Term(var_name, Term[]))
#         else
#             # Рекурсивно генерируем подтерм
#             child_term = generate_term_from_pattern(child_pattern)
#             push!(childs, child_term)
#         end
#     end
#     return Term(func_name, childs)
# end

# # Функция для генерации имени переменной
# function generate_variable_name(base_name::String)
#     return "$(base_name)$(rand(1:10))"
# end

# # Функция для переписывания терма согласно правилам TRS
# function rewrite_term(term::Term, trs_rules::Vector{<:Dict})
#     # Поиск первого применимого правила
#     for rule in trs_rules
#         left_pattern = parse_json_term(rule["left"])
#         right_replacement = parse_json_term(rule["right"])
#         result = match_and_replace(term, left_pattern, right_replacement)
#         if result !== nothing
#             return result
#         end
#     end
#     # Если ни одно правило не применимо, возвращаем исходный терм
#     return term
# end

# # Функция для преобразования JSON терма в структуру Term
# function parse_json_term(json_term::Dict)
#     childs = [parse_json_term(child) for child in json_term["childs"]]
#     return Term(json_term["value"], childs)
# end

# # Функция для сопоставления и замены терма по правилу
# function match_and_replace(term::Term, pattern::Term, replacement::Term)
#     var_map = Dict{String, Term}()
#     if match_term(term, pattern, var_map)
#         return substitute_vars(replacement, var_map)
#     else
#         # Рекурсивно пытаемся переписать дочерние термы
#         for i in 1:length(term.childs)
#             new_child = match_and_replace(term.childs[i], pattern, replacement)
#             if new_child !== nothing
#                 # Создаем новый терм с замененным дочерним термом
#                 new_childs = copy(term.childs)
#                 new_childs[i] = new_child
#                 return Term(term.name, new_childs)
#             end
#         end
#     end
#     return nothing
# end

# # Функция для сопоставления термов и заполнения var_map
# function match_term(term::Term, pattern::Term, var_map::Dict{String, Term})
#     if is_variable(pattern.name)
#         var_map[pattern.name] = term
#         return true
#     elseif term.name == pattern.name && length(term.childs) == length(pattern.childs)
#         for (t_child, p_child) in zip(term.childs, pattern.childs)
#             if !match_term(t_child, p_child, var_map)
#                 return false
#             end
#         end
#         return true
#     else
#         return false
#     end
# end


# # Функция для проверки, является ли имя переменной (например, начинается с маленькой буквы)
# function is_variable(name::String)
#     return startswith(name, "x") || startswith(name, "y") || startswith(name, "z")
# end

# # Функция для подстановки переменных из var_map в терм
# function substitute_vars(term::Term, var_map::Dict{String, Term})
#     if is_variable_name(term.name) && haskey(var_map, term.name)
#         return var_map[term.name]
#     else
#         new_childs = [substitute_vars(child, var_map) for child in term.childs]
#         return Term(term.name, new_childs)
#     end
# end

# end # module TermGenerator
