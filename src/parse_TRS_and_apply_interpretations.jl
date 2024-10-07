include("types.jl")

using Symbolics
using JSON

struct MissingJSONField <: Exception
           field
end

Base.showerror(io::IO, e::MissingJSONField) = print(io, "JSON поле $(e.field) не определено")

############################ Функция для применения интерпретаций
function apply_interpretation(term, interpretations)::String
    if isempty(term.childs)
        # Если это переменная, возвращаем ее имя
        return term.name
    else
        # Применяем интерпретацию для функции
        interpreted_childs = [apply_interpretation(child, interpretations) for child ∈ term.childs]
        if haskey(interpretations, term.name)
            interp_func = interpretations[term.name]
            # Вызываем функцию интерпретации с подставленными дочерними термами
            return interp_func(interpreted_childs...)
        else
            return "$(term.name)(" * join(interpreted_childs, ", ") * ")"
        end
    end
end

########################### Функция для переименования переменных в TRS
function renamevars!(term1, term2, renamefunc)
    rename! = function (t)
        if isempty(t.childs)
            t.name = renamefunc(t.name)
        else
            foreach(rename!, t.childs)
        end
    end

    foreach(rename!, (term1, term2))
end

"""
Разделяет переменные в каждом выражении, добавляя
индекс
"""
function separatevars!(term_pairs)
    for (index, pair) ∈ enumerate(term_pairs)
        renamevars!(pair[1], pair[2], x -> "$(x)_$index")
    end
end

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

"""
Возвращает вектор переменных и вектор полимномов, всё в виде строк
"""
function get_term_pairs_from_JSON(json_TRS_string)
    parsed_json = JSON.parse(json_TRS_string)
    term_pairs = Vector()
    if !isa(parsed_json, Array)
        throw(ArgumentError("ожидаетя массив JSON правил"))
    end
    for rule ∈ parsed_json
        if !haskey(rule, "left")
            throw(MissingJSONField("left"))
        end
        if !haskey(rule, "right")
            throw(MissingJSONField("right"))
        end
        left_term = make_term_from_json(rule["left"])
        right_term = make_term_from_json(rule["right"])
        push!(term_pairs, (left_term, right_term))
    end
    term_pairs
end

function parse_and_interpret(term_pairs, interpretations)
    variables_array = Vector()
    simplified_left_parts = Vector()
    for term_pair ∈ term_pairs
        left_term = term_pair[1]
        right_term = term_pair[2]

        # Собираем переменные из текущего правила
        variable_names = collect_vars(left_term) ∪ collect_vars(right_term)

        # Динамически объявляем переменные
        variable_symbols = Symbol.(collect(variable_names))
        @eval @variables $(variable_symbols...)

        append!(variables_array, string.(variable_symbols))

        # Применяем интерпретацию к левой и правой части текущего правила
        interpreted_left = apply_interpretation(left_term, interpretations)
        interpreted_right = apply_interpretation(right_term, interpretations)

        # Выводим правило TRSS
        left_term_str = term_to_string(left_term)
        right_term_str = term_to_string(right_term)

        println("\nПравило TRS:")
        println("$left_term_str -> $right_term_str")

        # Упрощение интерпретаций
        left_expr_expanded, right_expr_expanded = (interpreted_left, interpreted_right) .|> 
            Meta.parse .|> 
            eval .|> 
            Symbolics.simplify .|>
            Symbolics.expand

        # Вычисляем разность и упрощаем
        difference = Symbolics.simplify(left_expr_expanded - right_expr_expanded)
        difference_expanded = Symbolics.expand(difference)

        println("Выражение:")
        println("$(left_expr_expanded) = $(right_expr_expanded)")
        println("После упрощения:")
        println("$(difference_expanded) = 0")

        # Сохраняем левую часть выражения
        push!(simplified_left_parts, string(difference_expanded))
    end

    variables_array, simplified_left_parts
end

########################## Функция для парсинга интерпретаций
function parse_interpretations(json_interpret_string)
    interpretations::Dict{String, Function} = Dict()

    parsed_data = JSON.parse(json_interpret_string)
    for func ∈ parsed_data["functions"]
        func_name = func["name"]
        variables = func["variables"]
        expression = func["expression"]

        # Создаем функцию с необходимым количеством переменных
        interpretations[func_name] = (vars...) -> begin
            expr = expression
            # Заменяем переменные в выражении на соответствующие переменные из TRS
            for (i, var) ∈ enumerate(variables)
                # Используем регулярные выражения для замены целых слов
                expr = replace(expr, Regex("\\b$(var)\\b") => vars[i])
            end
            return expr
        end
    end

    interpretations
end

########################################## Функция для парсинга термов
# Функция для парсинга термов из JSON
function make_term_from_json(json::Dict)
    childs = [make_term_from_json(child) for child ∈ json["childs"]]
    return Term(json["value"], childs)
end

# Функция для отображения терма в человекочитаемом виде
# function term_to_string(term::Term)
#     if isempty(term.childs)
#         return term.name  # Если терм — переменная, возвращаем его имя
#     else
#         # Рекурсивно обрабатываем дочерние термы
#         child_strings = [term_to_string(child) for child ∈ term.childs]
#         return "$(term.name)(" * join(child_strings, ", ") * ")"
#     end
# end


"""
Возвращает вектор строк правил TRS
"""
function json_trs_to_string(json_string)
    all_rules_in_string = Vector()

    parsed_json = JSON.parse(json_string)

    # Проверяем, что parsed_json является массивом правил
    if !isa(parsed_json, Array)
        throw(ArgumentError("ожидаетcя массив JSON правил"))
    end

    # Проходим по каждому правилу в массиве
    for rule ∈ parsed_json
        # Проверяем, что правило содержит ключи "left" и "right"
        if !haskey(rule, "left")
            throw(MissingJSONField("left"))
        end
        if !haskey(rule, "right")
            throw(MissingJSONField("right"))
        end
        # Парсим левую и правую части правила
        left_term = make_term_from_json(rule["left"])
        right_term = make_term_from_json(rule["right"])

        # Выводим правило TRS
        left_term_str = term_to_string(left_term)
        right_term_str = term_to_string(right_term)
        rule_in_string = "$left_term_str -> $right_term_str"
        push!(all_rules_in_string, rule_in_string)
        println("\nПравило TRS:")
        println(rule_in_string)
    end

    return all_rules_in_string
end
