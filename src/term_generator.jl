include("types.jl")
include("reply_func.jl")
include("parse_TRS_and_apply_interpretations.jl")

using Random
using JSON

function change_random_leaf(tree, new_leaf)
    leaves = []

    ### Вспомогательная рекурсивная функция для сбора листьев
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

function build_example_term(term_pairs)
    rewriting_count = min(length(term_pairs)*2, 10)
    random_left_part = () -> deepcopy(rand(term_pairs)[1])
    root = Term("x", Vector(), true)
    for _ = 1:rewriting_count
        change_random_leaf(root, random_left_part())
    end
    root
end

function bind_terms!(TRS_term, term, binding_map)::Bool
    TRS_term.name ≠ term.name && return false

    arguments_relation = zip(TRS_term.childs, term.childs)
    
    for args ∈ arguments_relation
        if !isempty(args[1].childs)
            if args[1].name ≠ args[2].name
                return false
            end
            return bind_terms!(args[1], args[2], binding_map)
        else
            if haskey(binding_map, args[1])
                binding_map[args[1].name] ≠ args[2] && return false
            else
                binding_map[args[1].name] = args[2]
            end
        end
    end
    true
end

function rewrite_term(term, term_pairs)
    function rename_leaves(inner_term, var_map)
        if isempty(inner_term.childs)
            var_map[inner_term.name]
        else
            Term(inner_term.name, map(
                x -> rename_leaves(x, var_map),
                inner_term.childs),
                inner_term.is_variable
            )
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
            Term(term.name, map(x -> rewrite_term(x, term_pairs), term.childs), term.is_variable)
        else
            Term(term.name, [], term.is_variable)
        end

    end
end

function get_demo(term_pairs, interpretations)
    res = ""
    before = build_example_term(term_pairs)
    after = rewrite_term(before, term_pairs)

    text_reply("Случайный терм до переписывания:")
    code_reply("$(term_to_string(before))")
    text_reply("Терм после переписывания:")
    code_reply("$(term_to_string(after))")

    res *= "\nСлучайный терм до переписывания: $(term_to_string(before))\n"
    res *= "Терм после переписывания: $(term_to_string(after))\n"
    vars = collect_vars(before)

    before = apply_interpretation(before, interpretations)
    after = apply_interpretation(after, interpretations)

    text_reply("Случайные значения переменных:")

    res *= "Случайные значения переменных:\n"
    for v ∈ vars 
        value = string(rand(1:10))

        code_reply("$v = $value")

        res *= "$v = $value\n"
        before = replace(before, v => value)
        after = replace(after, v => value)
    end
    l_value, r_value = map((before, after)) do x
        eval(Meta.parse(x))
    end

    text_reply("Вес терма до переписывания:")
    code_reply("$l_value")
    text_reply("Вес терма после переписывания:")
    code_reply("$r_value")

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

            text_reply("\nПереданный набор интерпретаций не доказывает завершаемость")
            code_reply("$(term_to_string(pair[1])) -> $(term_to_string(pair[2]))")
            code_reply("$var_string")
            text_reply("При подстановке вышеуказанных чисел получаем:")
            code_reply("$(eval(Meta.parse(left))) -> $(eval(Meta.parse(right)))")

            return """
            Переданный набор интерпретаций не доказывает завершаемость $(term_to_string(pair[1])) -> $(term_to_string(pair[2]))
            $var_string
            При подстановке вышеуказанных чисел получаем $(eval(Meta.parse(left))) -> $(eval(Meta.parse(right)))
            """
        end
    end
end
