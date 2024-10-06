include("Types.jl")
include("parse_TRS_and_apply_interpretations.jl")

using Random
using JSON

function change_random_leaf(tree, new_leaf)
    leaves = []

    # Вспомогательная рекурсивная функция для сбора листьев
    function collect_leaves(node, parent, index)
        if isempty(node.childs)
            push!(leaves, (node, parent, index))
        else
            for (i, child) ∈ enumerate(node.childs)
                collect_leaves(child, node, i)
            end
        end
    end

    collect_leaves(tree, nothing, nothing)

    if isempty(leaves)
        # Если в дереве нет листьев
        return
    end

    # Выбираем случайный лист
    idx = rand(eachindex(leaves))
    node, parent, index = leaves[idx]

    if parent ≡ nothing
        # Если лист является корнем дерева
        tree.name = new_leaf.name
        tree.childs = new_leaf.childs
    else
        # Заменяем лист на новый
        parent.childs[index] = new_leaf
    end
end


function replace_random_leaf(tree, new_term)
    # Function to collect all leaves in the tree
    function collect_leaves(node, leaves)
        if isempty(node.childs)
            push!(leaves, node)
        else
            for child ∈ node.childs
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
    replace_leaf = (node) -> begin
        if node ≡ random_leaf
            return new_term
        else
            for i ∈ 1:length(node.childs)
                node.childs[i] = replace_leaf(node.childs[i])
            end
            return node
        end
    end

    return replace_leaf(tree)
end

function build_example_term(term_pairs)
    rewriting_count = min(length(term_pairs)*2, 10)
    random_left_part = () -> deepcopy(rand(term_pairs)[1])
    root = Term("x", Vector())
    for _ = 1:rewriting_count
        change_random_leaf(root, random_left_part())
    end
    root
end

function bind_terms!(TRS_term, term, binding_map)::Bool
    arguments_relation = zip(TRS_term.childs, term.childs)
    ok = true
    for args ∈ arguments_relation
        if !isempty(args[1].childs)
            if args[1].name ≠ args[2].name
                ok = false
                break
            end
            bind_terms!(args[1], args[2], binding_map)
        else
            if haskey(binding_map, args[1])
                if binding_map[args[1].name] ≠ args[2] ok = false end
                break
            else
                binding_map[args[1].name] = args[2]
            end
        end
    end
    ok 
end

function rewrite_term(term, term_pairs)
    function rename_leaves(inner_term, var_map)
        if isempty(inner_term.childs)
            var_map[inner_term.name]
        else
            Term(inner_term.name, map(x -> rename_leaves(x, var_map), inner_term.childs))
        end
    end
    
    smth_rewrited = false
    for t ∈ term_pairs
        left_part = deepcopy(t[1])
        right_part = deepcopy(t[2])
        if left_part.name == term.name
            arguments_map = Dict()
            arguments_relation = zip(left_part.childs, term.childs)
            for args ∈ arguments_relation
                if !isempty(args[1].childs)
                    ok = bind_terms!(args[1], args[2], arguments_map)
                    ok || @goto outer_end
                else
                    arguments_map[args[1].name] = args[2]
                end
            end
            term = rename_leaves(right_part, arguments_map)
            smth_rewrited = true
        end
        @label outer_end
    end
    if smth_rewrited
        rewrite_term(term, term_pairs)
    else
        if !isempty(term.childs)
            Term(term.name, map(x -> rewrite_term(x, term_pairs), term.childs))
        else
            Term(term.name, [])
        end
    end
end

function get_demo(term_pairs, interpretations)
    res = ""
    before = build_example_term(term_pairs)
    after = rewrite_term(before, term_pairs)
    res *= "Терм до переписывания: $before\n"
    res *= "Терм после переписывания: $after\n"
    vars = collect_vars(before)

    before = apply_interpretation(before, interpretations)
    after = apply_interpretation(after, interpretations)

    for v ∈ vars 
        value = string(rand(1:10))
        before = replace(before, v => value)
        after = replace(after, v => value)
    end
    l_value, r_value = map((before, after)) do x
        eval(Meta.parse(x))
    end
    res *= "Вес терма до переписывания: $l_value\n"
    res *= "Вес терма после переписывания: $r_value\n"

    res
end

function get_counterexample(term_pairs, interpretations, var_map)
    for pair ∈ term_pairs
        left = apply_interpretation(pair[1], interpretations)
        right = apply_interpretation(pair[2], interpretations)
        for (var, value) ∈ var_map
            left = replace(left, var => value)
            right = replace(right, var => value)
        end
        if eval(Meta.parse("$left <= $right"))
            variables = collect_vars(pair[1]) ∪ collect_vars(pair[2])
            var_string = ""
            for v ∈ variables
                var_string *= "$v = $(var_map[v])\n"
            end
            return """
            Переданный набор интерпретаций не доказывает завершаемость $(term_to_string(pair[1])) -> $(term_to_string(pair[2]))
            $var_string
            При подстановке вышеуказанных чисел получаем $(eval(Meta.parse(left))) -> $(eval(Meta.parse(right)))
            """
        end
    end
end
